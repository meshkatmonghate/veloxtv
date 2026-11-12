use crate::models::{Category, ChannelItem, StreamType};
use std::collections::{HashMap, HashSet};

pub struct M3uParseResult {
    pub channels: Vec<ChannelItem>,
    pub categories: Vec<Category>,
}

pub struct M3uParser;

impl M3uParser {
    /// Fast streaming parser for M3U / M3U8 playlist content
    pub fn parse(content: &str) -> M3uParseResult {
        let mut channels = Vec::new();
        let mut category_names = HashSet::new();
        let mut current_extinf: Option<HashMap<String, String>> = None;
        let mut current_name = String::new();

        for line in content.lines() {
            let trimmed = line.trim();
            if trimmed.is_empty() {
                continue;
            }

            if trimmed.starts_with("#EXTINF:") {
                let (attributes, name) = Self::parse_extinf_line(trimmed);
                current_extinf = Some(attributes);
                current_name = name;
            } else if !trimmed.starts_with('#') {
                // This is a stream URL
                if let Some(attrs) = current_extinf.take() {
                    let tvg_id = attrs.get("tvg-id").cloned();
                    let tvg_logo = attrs.get("tvg-logo").cloned();
                    let group_title = attrs.get("group-title")
                        .cloned()
                        .unwrap_or_else(|| "Other / Uncategorized".to_string());

                    category_names.insert(group_title.clone());

                    let stream_url = trimmed.to_string();
                    let channel_id = format!("m3u_{}", channels.len() + 1);

                    channels.push(ChannelItem {
                        id: channel_id,
                        num: None,
                        name: if current_name.is_empty() { "Unnamed Stream".to_string() } else { current_name.clone() },
                        stream_id: None,
                        stream_icon: tvg_logo,
                        epg_channel_id: tvg_id,
                        category_id: group_title.clone(),
                        category_name: Some(group_title),
                        stream_url,
                        is_favorite: false,
                        is_locked: false,
                        stream_type: StreamType::Live,
                    });
                }
            }
        }

        let mut categories: Vec<Category> = category_names
            .into_iter()
            .map(|name| Category {
                id: name.clone(),
                name,
                is_hidden: false,
                is_locked: false,
                stream_type: StreamType::Live,
            })
            .collect();

        categories.sort_by(|a, b| a.name.cmp(&b.name));

        M3uParseResult {
            channels,
            categories,
        }
    }

    /// Helper to extract attributes like tvg-id="...", group-title="..." and channel title
    fn parse_extinf_line(line: &str) -> (HashMap<String, String>, String) {
        let mut attrs = HashMap::new();
        let mut channel_name = String::new();

        if let Some(comma_idx) = line.rfind(',') {
            channel_name = line[comma_idx + 1..].trim().to_string();
            let meta_part = &line[8..comma_idx]; // After #EXTINF:

            // Simple state machine to parse key="value"
            let mut chars = meta_part.chars().peekable();
            while let Some(c) = chars.next() {
                if c.is_alphanumeric() || c == '-' || c == '_' {
                    let mut key = String::new();
                    key.push(c);
                    while let Some(&next_c) = chars.peek() {
                        if next_c == '=' || next_c == ' ' {
                            break;
                        }
                        key.push(chars.next().unwrap());
                    }

                    // Skip whitespace before =
                    while let Some(&next_c) = chars.peek() {
                        if next_c == '=' {
                            chars.next();
                            break;
                        }
                        if next_c != ' ' {
                            break;
                        }
                        chars.next();
                    }

                    // Read value (quoted or unquoted)
                    let mut val = String::new();
                    if let Some(&'"') = chars.peek() {
                        chars.next(); // Consume opening quote
                        while let Some(vc) = chars.next() {
                            if vc == '"' {
                                break;
                            }
                            val.push(vc);
                        }
                    } else {
                        while let Some(&vc) = chars.peek() {
                            if vc == ' ' || vc == ',' {
                                break;
                            }
                            val.push(chars.next().unwrap());
                        }
                    }

                    if !key.is_empty() {
                        attrs.insert(key.to_lowercase(), val);
                    }
                }
            }
        }

        (attrs, channel_name)
    }
}
