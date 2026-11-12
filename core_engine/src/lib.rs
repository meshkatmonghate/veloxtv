pub mod models;
pub mod xc_client;
pub mod m3u_parser;
pub mod security;
pub mod recorder;

pub use models::*;
pub use xc_client::XtreamClient;
pub use m3u_parser::{M3uParser, M3uParseResult};
pub use security::ParentalConfig;
pub use recorder::{StreamRecorder, RecordingInfo};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_m3u_parser_basic() {
        let sample_m3u = r#"
#EXTM3U
#EXTINF:-1 tvg-id="bbc1.uk" tvg-name="BBC One" tvg-logo="http://logo.com/bbc1.png" group-title="UK Entertainment",BBC One HD
http://stream.example.com/live/bbc1.m3u8
#EXTINF:-1 tvg-id="cnn.us" tvg-name="CNN" group-title="News",CNN International
http://stream.example.com/live/cnn.ts
"#;

        let result = M3uParser::parse(sample_m3u);
        assert_eq!(result.channels.len(), 2);
        assert_eq!(result.categories.len(), 2);

        let ch1 = &result.channels[0];
        assert_eq!(ch1.name, "BBC One HD");
        assert_eq!(ch1.category_id, "UK Entertainment");
        assert_eq!(ch1.epg_channel_id.as_deref(), Some("bbc1.uk"));
        assert_eq!(ch1.stream_icon.as_deref(), Some("http://logo.com/bbc1.png"));
        assert_eq!(ch1.stream_url, "http://stream.example.com/live/bbc1.m3u8");

        let ch2 = &result.channels[1];
        assert_eq!(ch2.name, "CNN International");
        assert_eq!(ch2.category_id, "News");
    }

    #[test]
    fn test_parental_control_pin_and_adult_filtering() {
        let mut pc = ParentalConfig::new("1234");
        assert!(pc.is_enabled);
        assert!(pc.verify_pin("1234"));
        assert!(!pc.verify_pin("0000"));

        // Adult category check
        assert!(pc.is_category_locked("cat_99", "XXX Adult Movies"));
        assert!(pc.is_category_locked("cat_100", "18+ Channels"));
        assert!(!pc.is_category_locked("cat_1", "Documentary"));

        // Manual lock
        pc.toggle_category_lock("cat_1");
        assert!(pc.is_category_locked("cat_1", "Documentary"));

        // Hide category
        assert!(pc.is_category_visible("cat_news"));
        pc.toggle_category_visibility("cat_news");
        assert!(!pc.is_category_visible("cat_news"));
    }
}
