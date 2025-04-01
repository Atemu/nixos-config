use serde::Deserialize;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::os::unix::fs::MetadataExt;
use std::path::PathBuf;
use std::process;
use thiserror::Error;
mod mode;
use mode::Mode;
use users::get_user_by_uid;

#[derive(Deserialize, Debug)]
struct Secret {
    path: PathBuf,
    user: String,
    group: String,
    mode: Mode, // TODO more abstract type?
}

#[derive(Error, Debug)]
#[error("found {found}, expected {expected}")]
struct ModeMismatchError {
    expected: Mode,
    found: Mode,
}
fn verify_mode(secret: &Secret) -> Result<(), ModeMismatchError> {
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

#[derive(Error, Debug)]
#[error("found {found}, expected {expected}")]
struct OwnerMismatchError {
    expected: String,
    found: String,
}
fn verify_owner(secret: &Secret) -> Result<(), OwnerMismatchError> {
    let metadata = fs::metadata(&secret.path).unwrap(); // Don't care about permission issues, this is supposed to be run as root
    let uid = metadata.uid();
    let owner_name = match get_user_by_uid(uid) {
        Some(o) => o.name().to_str().unwrap().to_owned(), // Great code. Best code I've written in a while. Such saftey. Much wow.
        None => {
            return Err(OwnerMismatchError {
                expected: secret.user.clone(),
                found: uid.to_string(),
            });
        }
    };
    if owner_name != secret.user {
        return Err(OwnerMismatchError {
            expected: secret.user.clone(),
            found: owner_name,
        });
    }

    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let spec_file = &args[1];

    let contents = fs::read_to_string(spec_file).expect("Should have been able to read the file");
    let spec: HashMap<String, Secret> = serde_json::from_str(&contents).unwrap();

    let mut any_err = false;
    for (name, secret) in spec {
        let mut is_err = false;

        if !secret.path.exists() {
            any_err = true;
            println!(
                "Secret '{name}' does not exist at '{}'.",
                secret.path.display()
            );
            continue;
        }

        let mode_result = verify_mode(&secret);
        if mode_result.is_err() {
            is_err = true;
            print!(
                "Secret '{name}' at '{}' has wrong mode: ",
                secret.path.display()
            );
            println!("{}.", mode_result.err().unwrap());
        }

        let owner_result = verify_owner(&secret);
        if owner_result.is_err() {
            is_err = true;
            print!(
                "Secret '{name}' at '{}' has wrong owner: ",
                secret.path.display()
            );
            println!("{}.", owner_result.err().unwrap());
        }

        if is_err {
            any_err = true;
        } else {
            println!("Secret '{name}' at '{}' is correct.", secret.path.display());
        }
    }

    if any_err {
        process::exit(1);
    }
}
