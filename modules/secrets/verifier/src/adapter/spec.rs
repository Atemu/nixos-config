use std::{collections::HashMap, path::Path};

use serde::Deserialize;
use users::{get_group_by_name, get_user_by_name};

use crate::domain::mode::Mode;
use crate::domain::secret::Secret;

pub type SpecName = String;

#[derive(Deserialize, Debug)]
pub struct SpecItem {
    path: String,
    user: String,
    group: String,
    mode: String,
}

impl SpecItem {
    pub fn to_secret(&self) -> Option<Secret> {
        // TODO Result
        Some(Secret::new(
            Path::new(&self.path).to_path_buf(),
            get_user_by_name(&self.user)?,
            get_group_by_name(&self.group)?,
            Mode::from_string(&self.mode).ok()?,
        ))
    }
}

#[derive(Deserialize, Debug)]
pub struct SpecData(HashMap<SpecName, SpecItem>);
impl SpecData {
    pub fn to_secret_spec(&self) -> Option<crate::domain::secret::SecretSpec> {
        self.0
            .iter()
            .map(|(k, v)| (k.clone(), v.to_secret()))
            // We must map the inner value of the option for it to be
            // collectible into an optional collection
            .map(|(k, v)| v.map(|o| (k.clone(), o)))
            .collect()
    }
}
