use sha2::{Digest, Sha256};
use std::collections::HashSet;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParentalConfig {
    pub is_enabled: bool,
    pub pin_hash: String,
    pub locked_category_ids: HashSet<String>,
    pub hidden_category_ids: HashSet<String>,
    pub lock_adult_auto: bool,
}

impl Default for ParentalConfig {
    fn default() -> Self {
        Self {
            is_enabled: false,
            pin_hash: String::new(),
            locked_category_ids: HashSet::new(),
            hidden_category_ids: HashSet::new(),
            lock_adult_auto: true,
        }
    }
}

impl ParentalConfig {
    pub fn new(pin: &str) -> Self {
        let mut cfg = Self::default();
        cfg.set_pin(pin);
        cfg.is_enabled = true;
        cfg
    }

    pub fn set_pin(&mut self, pin: &str) {
        let mut hasher = Sha256::new();
        hasher.update(pin.as_bytes());
        self.pin_hash = format!("{:x}", hasher.finalize());
        self.is_enabled = true;
    }

    pub fn verify_pin(&self, pin: &str) -> bool {
        if !self.is_enabled || self.pin_hash.is_empty() {
            return true;
        }
        let mut hasher = Sha256::new();
        hasher.update(pin.as_bytes());
        let input_hash = format!("{:x}", hasher.finalize());
        input_hash == self.pin_hash
    }

    pub fn toggle_category_lock(&mut self, category_id: &str) -> bool {
        if self.locked_category_ids.contains(category_id) {
            self.locked_category_ids.remove(category_id);
            false
        } else {
            self.locked_category_ids.insert(category_id.to_string());
            true
        }
    }

    pub fn toggle_category_visibility(&mut self, category_id: &str) -> bool {
        if self.hidden_category_ids.contains(category_id) {
            self.hidden_category_ids.remove(category_id);
            false // Not hidden
        } else {
            self.hidden_category_ids.insert(category_id.to_string());
            true // Hidden
        }
    }

    pub fn is_category_visible(&self, category_id: &str) -> bool {
        !self.hidden_category_ids.contains(category_id)
    }

    pub fn is_category_locked(&self, category_id: &str, category_name: &str) -> bool {
        if !self.is_enabled {
            return false;
        }

        if self.locked_category_ids.contains(category_id) {
            return true;
        }

        // Automatic adult content check
        if self.lock_adult_auto {
            let lower = category_name.to_lowercase();
            if lower.contains("adult")
                || lower.contains("xxx")
                || lower.contains("18+")
                || lower.contains("porn")
                || lower.contains("erotic")
            {
                return true;
            }
        }

        false
    }
}
