use super::mode::Mode;
use lombok::AllArgsConstructor;
use std::{collections::HashMap, fs, os::unix::fs::MetadataExt, path::PathBuf};
use thiserror::Error;
use users::{get_group_by_gid, get_user_by_uid, Group, User};

pub type SecretName = String;

#[derive(Debug, AllArgsConstructor)]
pub struct Secret {
    // TODO rename SecretSpec
    pub path: PathBuf, // TODO implement exists() as pub method
    user: User,
    group: Group,
    mode: Mode,
}

#[derive(Error, Debug)]
#[error("found {found}, expected {expected}")]
pub struct ModeMismatchError {
    expected: Mode,
    found: Mode,
}
// TODO impl methods
pub fn verify_mode(secret: &Secret) -> Result<(), ModeMismatchError> {
    let spec_mode = &secret.mode;
    let metadata = fs::metadata(&secret.path).unwrap(); // Don't care about permission issues, this is supposed to be run as root
    let mode = Mode::from_u32(metadata.mode());
    if mode != *spec_mode {
        return Err(ModeMismatchError {
            expected: *spec_mode,
            found: mode,
        });
    }

    Ok(())
}

fn get_name(user: &User) -> String {
    user.name().to_str().unwrap_or("unknown").to_owned()
}

#[derive(Error, Debug)]
#[error("found {found}, expected {expected}")]
pub struct OwnerMismatchError {
    expected: String,
    found: String,
}
pub fn verify_owner(secret: &Secret) -> Result<(), OwnerMismatchError> {
    let metadata = fs::metadata(&secret.path).unwrap(); // Don't care about permission issues, this is supposed to be run as root
    let uid = metadata.uid();
    let file_owner = match get_user_by_uid(uid) {
        Some(o) => o,
        None => {
            return Err(OwnerMismatchError {
                expected: get_name(&secret.user),
                found: uid.to_string(),
            });
        }
    };
    if file_owner.uid() != secret.user.uid() {
        return Err(OwnerMismatchError {
            expected: get_name(&secret.user),
            found: get_name(&file_owner),
        });
    }

    Ok(())
}

fn get_group(user: &Group) -> String {
    user.name().to_str().unwrap_or("unknown").to_owned()
}

#[derive(Error, Debug)]
#[error("found {found}, expected {expected}")]
pub struct GroupMismatchError {
    expected: String,
    found: String,
}
// TODO unify with above function
pub fn verify_group(secret: &Secret) -> Result<(), OwnerMismatchError> {
    let metadata = fs::metadata(&secret.path).unwrap(); // Don't care about permission issues, this is supposed to be run as root
    let gid = metadata.gid();
    let file_group = match get_group_by_gid(gid) {
        Some(o) => o,
        None => {
            return Err(OwnerMismatchError {
                expected: get_group(&secret.group),
                found: gid.to_string(),
            });
        }
    };
    if file_group.gid() != secret.group.gid() {
        return Err(OwnerMismatchError {
            expected: get_name(&secret.user),
            found: get_group(&file_group),
        });
    }

    Ok(())
}

pub type SecretSpec = HashMap<SecretName, Secret>;
