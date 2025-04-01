use serde::Deserialize;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::os::unix::fs::MetadataExt;
use std::path::Path;
use std::process;
use thiserror::Error;
mod mode;
use mode::Mode;

#[derive(Deserialize, Debug)]
struct Secret {
    path: String, // TODO path type
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
    let path = Path::new(&secret.path);

    let spec_mode = &secret.mode;
    let metadata = fs::metadata(path).unwrap(); // Don't care about permission issues, this is supposed to be run as root
    let mode = Mode::from_u32(metadata.mode());
    if mode != *spec_mode {
        return Err(ModeMismatchError {
            expected: *spec_mode,
            found: mode,
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

        if !Path::new(&secret.path).exists() {
            any_err = true;
            println!("Secret '{name}' does not exist at '{}'.", secret.path);
            continue;
        }

        let mode_result = verify_mode(&secret);
        if mode_result.is_err() {
            is_err = true;
            print!("Secret '{name}' at '{}' has wrong mode: ", secret.path);
            println!("{}.", mode_result.err().unwrap());
        } else {
            println!("Secret '{name}' at '{}' is correct.", secret.path);
        }

        if is_err {
            any_err = true;
        }
    }

    if any_err {
        process::exit(1);
    }
}
