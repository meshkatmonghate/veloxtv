use anyhow::{anyhow, Result};
use chrono::{DateTime, Utc};
use futures_util::StreamExt;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::fs::File;
use tokio::io::AsyncWriteExt;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecordingInfo {
    pub id: String,
    pub channel_id: String,
    pub channel_name: String,
    pub output_path: String,
    pub start_time: DateTime<Utc>,
    pub end_time: Option<DateTime<Utc>>,
    pub total_bytes: u64,
    pub is_active: bool,
}

pub struct StreamRecorder {
    is_recording: Arc<AtomicBool>,
    bytes_written: Arc<AtomicU64>,
}

impl StreamRecorder {
    pub fn new() -> Self {
        Self {
            is_recording: Arc::new(AtomicBool::new(false)),
            bytes_written: Arc::new(AtomicU64::new(0)),
        }
    }

    pub fn is_active(&self) -> bool {
        self.is_recording.load(Ordering::SeqCst)
    }

    pub fn get_bytes_written(&self) -> u64 {
        self.bytes_written.load(Ordering::SeqCst)
    }

    pub fn stop(&self) {
        self.is_recording.store(false, Ordering::SeqCst);
    }

    /// Record live stream to local file asynchronously
    pub async fn start_recording(
        &self,
        stream_url: &str,
        output_file_path: PathBuf,
    ) -> Result<()> {
        if self.is_active() {
            return Err(anyhow!("Recording is already in progress"));
        }

        self.is_recording.store(true, Ordering::SeqCst);
        self.bytes_written.store(0, Ordering::SeqCst);

        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .build()?;

        let res = client.get(stream_url).send().await?;
        if !res.status().is_success() {
            self.is_recording.store(false, Ordering::SeqCst);
            return Err(anyhow!("Failed to connect to stream: HTTP {}", res.status()));
        }

        if let Some(parent) = output_file_path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }

        let mut file = File::create(&output_file_path).await?;
        let mut stream = res.bytes_stream();

        let is_running = self.is_recording.clone();
        let bytes_counter = self.bytes_written.clone();

        tokio::spawn(async move {
            while is_running.load(Ordering::SeqCst) {
                match stream.next().await {
                    Some(Ok(chunk)) => {
                        if file.write_all(&chunk).await.is_err() {
                            break;
                        }
                        bytes_counter.fetch_add(chunk.len() as u64, Ordering::SeqCst);
                    }
                    Some(Err(_)) => break,
                    None => break,
                }
            }

            let _ = file.flush().await;
            is_running.store(false, Ordering::SeqCst);
        });

        Ok(())
    }
}
