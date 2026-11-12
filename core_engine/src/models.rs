use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum StreamType {
    Live,
    Movie,
    Series,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Category {
    pub id: String,
    pub name: String,
    pub is_hidden: bool,
    pub is_locked: bool,
    pub stream_type: StreamType,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelItem {
    pub id: String,
    pub num: Option<u32>,
    pub name: String,
    pub stream_id: Option<u32>,
    pub stream_icon: Option<String>,
    pub epg_channel_id: Option<String>,
    pub category_id: String,
    pub category_name: Option<String>,
    pub stream_url: String,
    pub is_favorite: bool,
    pub is_locked: bool,
    pub stream_type: StreamType,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VodItem {
    pub stream_id: u32,
    pub name: String,
    pub title: Option<String>,
    pub stream_icon: Option<String>,
    pub rating: Option<f32>,
    pub category_id: String,
    pub container_extension: String,
    pub direct_source: Option<String>,
    pub stream_url: String,
    pub resume_position_ms: u64,
    pub duration_ms: u64,
    pub is_favorite: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SeriesItem {
    pub series_id: u32,
    pub name: String,
    pub cover: Option<String>,
    pub plot: Option<String>,
    pub cast: Option<String>,
    pub rating: Option<f32>,
    pub category_id: String,
    pub is_favorite: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XtreamUserInfo {
    pub username: String,
    pub status: String,
    pub exp_date: Option<String>,
    pub is_trial: Option<String>,
    pub active_cons: Option<String>,
    pub max_connections: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XtreamServerInfo {
    pub url: String,
    pub port: String,
    pub https_port: Option<String>,
    pub server_protocol: Option<String>,
    pub timezone: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XtreamAuthResponse {
    pub user_info: XtreamUserInfo,
    pub server_info: XtreamServerInfo,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EpgProgram {
    pub id: String,
    pub title: String,
    pub start: String,
    pub end: String,
    pub description: Option<String>,
}
