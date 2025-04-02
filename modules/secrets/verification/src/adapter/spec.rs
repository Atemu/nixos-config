use std::{
    collections::HashMap,
    path::{Path, PathBuf},
};

use serde::Deserialize;
use users::{get_group_by_name, get_user_by_name, Group};

use crate::domain::{mode::Mode, secret::Secret};

pub type SpecName = String;

#[derive(Deserialize, Debug)]
pub struct SpecItem {
    path: String,
    user: String,
    group: String,
    mode: String,
}

impl SpecItem {
    pub fn to_secret(&self) -> Secret {
        // TODO Result
        Secret::new(
            Path::new(&self.path).to_path_buf(),
            get_user_by_name(&self.user).unwrap(), // TODO
            get_group_by_name(&self.group).unwrap(), // TODO
            Mode::from_string(&self.mode).unwrap(), // TODO
        )
    }
}

#[derive(Deserialize, Debug)]
pub struct SpecData(HashMap<SpecName, SpecItem>);
impl SpecData {
    pub fn to_secret_spec(&self) -> crate::domain::secret::SecretSpec {
        let value = self
            .0
            .iter()
            .map(|(n, v)| (n.clone(), v.to_secret()))
            .collect();
        value
    }
}
