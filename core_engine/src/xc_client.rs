use crate::models::*;
use anyhow::{anyhow, Result};
use reqwest::Client;
use serde_json::Value;
use std::time::Duration;

#[derive(Clone, Debug)]
pub struct XtreamClient {
    pub base_url: String,
    pub username: String,
    pub password: String,
    http_client: Client,
}

impl XtreamClient {
    pub fn new(base_url: String, username: String, password: String) -> Self {
        let mut clean_url = base_url.trim().trim_end_matches('/').to_string();
        if !clean_url.starts_with("http://") && !clean_url.starts_with("https://") {
            clean_url = format!("http://{}", clean_url);
        }

        let http_client = Client::builder()
            .timeout(Duration::from_secs(15))
            .build()
            .unwrap_or_else(|_| Client::new());

        Self {
            base_url: clean_url,
            username,
            password,
            http_client,
        }
    }

    fn build_api_url(&self, action: Option<&str>, extra_params: &[(&str, &str)]) -> String {
        let mut url = format!(
            "{}/player_api.php?username={}&password={}",
            self.base_url, self.username, self.password
        );
        if let Some(act) = action {
            url.push_str(&format!("&action={}", act));
        }
        for (k, v) in extra_params {
            url.push_str(&format!("&{}={}", k, v));
        }
        url
    }

    /// Authenticate with Xtream Codes server
    pub async fn authenticate(&self) -> Result<XtreamAuthResponse> {
        let url = self.build_api_url(None, &[]);
        let res = self.http_client.get(&url).send().await?;
        if !res.status().is_success() {
            return Err(anyhow!("Authentication failed with status: {}", res.status()));
        }

        let val: Value = res.json().await?;
        let user_info = val.get("user_info")
            .ok_or_else(|| anyhow!("Invalid Xtream Codes credentials or server error"))?;

        let auth_status = user_info.get("auth").and_then(|v| v.as_i64()).unwrap_or(0);
        if auth_status != 1 {
            return Err(anyhow!("Authentication rejected: Invalid username or password"));
        }

        let parsed: XtreamAuthResponse = serde_json::from_value(val)?;
        Ok(parsed)
    }

    /// Fetch Live Categories
    pub async fn get_live_categories(&self) -> Result<Vec<Category>> {
        let url = self.build_api_url(Some("get_live_categories"), &[]);
        let res = self.http_client.get(&url).send().await?;
        let items: Vec<Value> = res.json().await?;

        let mut categories = Vec::new();
        for item in items {
            if let (Some(id), Some(name)) = (
                item.get("category_id").and_then(|v| v.as_str()),
                item.get("category_name").and_then(|v| v.as_str()),
            ) {
                categories.push(Category {
                    id: id.to_string(),
                    name: name.to_string(),
                    is_hidden: false,
                    is_locked: false,
                    stream_type: StreamType::Live,
                });
            }
        }
        Ok(categories)
    }

    /// Fetch Live Streams (optionally by category_id)
    pub async fn get_live_streams(&self, category_id: Option<&str>) -> Result<Vec<ChannelItem>> {
        let mut params = Vec::new();
        if let Some(cid) = category_id {
            params.push(("category_id", cid));
        }
        let url = self.build_api_url(Some("get_live_streams"), &params);
        let res = self.http_client.get(&url).send().await?;
        let items: Vec<Value> = res.json().await?;

        let mut channels = Vec::new();
        for item in items {
            let stream_id = item.get("stream_id").and_then(|v| v.as_u64()).map(|v| v as u32);
            let name = item.get("name").and_then(|v| v.as_str()).unwrap_or("Unknown").to_string();
            let cat_id = item.get("category_id").and_then(|v| v.as_str()).unwrap_or("0").to_string();
            let icon = item.get("stream_icon").and_then(|v| v.as_str()).map(|s| s.to_string());
            let epg_id = item.get("epg_channel_id").and_then(|v| v.as_str()).map(|s| s.to_string());
            let num = item.get("num").and_then(|v| v.as_u64()).map(|v| v as u32);

            let s_id = stream_id.unwrap_or(0);
            let stream_url = format!("{}/live/{}/{}/{}.ts", self.base_url, self.username, self.password, s_id);

            channels.push(ChannelItem {
                id: format!("xc_live_{}", s_id),
                num,
                name,
                stream_id,
                stream_icon: icon,
                epg_channel_id: epg_id,
                category_id: cat_id,
                category_name: None,
                stream_url,
                is_favorite: false,
                is_locked: false,
                stream_type: StreamType::Live,
            });
        }
        Ok(channels)
    }

    /// Fetch VOD Categories
    pub async fn get_vod_categories(&self) -> Result<Vec<Category>> {
        let url = self.build_api_url(Some("get_vod_categories"), &[]);
        let res = self.http_client.get(&url).send().await?;
        let items: Vec<Value> = res.json().await?;

        let mut categories = Vec::new();
        for item in items {
            if let (Some(id), Some(name)) = (
                item.get("category_id").and_then(|v| v.as_str()),
                item.get("category_name").and_then(|v| v.as_str()),
            ) {
                categories.push(Category {
                    id: id.to_string(),
                    name: name.to_string(),
                    is_hidden: false,
                    is_locked: false,
                    stream_type: StreamType::Movie,
                });
            }
        }
        Ok(categories)
    }

    /// Fetch VOD Streams
    pub async fn get_vod_streams(&self, category_id: Option<&str>) -> Result<Vec<VodItem>> {
        let mut params = Vec::new();
        if let Some(cid) = category_id {
            params.push(("category_id", cid));
        }
        let url = self.build_api_url(Some("get_vod_streams"), &params);
        let res = self.http_client.get(&url).send().await?;
        let items: Vec<Value> = res.json().await?;

        let mut vods = Vec::new();
        for item in items {
            let stream_id = item.get("stream_id").and_then(|v| v.as_u64()).unwrap_or(0) as u32;
            let name = item.get("name").and_then(|v| v.as_str()).unwrap_or("Unknown").to_string();
            let cat_id = item.get("category_id").and_then(|v| v.as_str()).unwrap_or("0").to_string();
            let icon = item.get("stream_icon").and_then(|v| v.as_str()).map(|s| s.to_string());
            let rating = item.get("rating").and_then(|v| v.as_f64()).map(|r| r as f32);
            let ext = item.get("container_extension").and_then(|v| v.as_str()).unwrap_or("mp4").to_string();

            let stream_url = format!("{}/movie/{}/{}/{}.{}", self.base_url, self.username, self.password, stream_id, ext);

            vods.push(VodItem {
                stream_id,
                name,
                title: None,
                stream_icon: icon,
                rating,
                category_id: cat_id,
                container_extension: ext,
                direct_source: None,
                stream_url,
                resume_position_ms: 0,
                duration_ms: 0,
                is_favorite: false,
            });
        }
        Ok(vods)
    }

    /// Build HLS stream URL if preferred over MPEG-TS
    pub fn build_live_hls_url(&self, stream_id: u32) -> String {
        format!("{}/live/{}/{}/{}.m3u8", self.base_url, self.username, self.password, stream_id)
    }
}
