use serde::{Deserialize, Serialize};
use std::env;
use std::fs;
use std::process;
use std::path::Path;
use std::os::unix::fs::MetadataExt;
use thiserror::Error;
// use std::fs::File;

#[derive(Serialize, Deserialize, Debug)]
struct Secret {
    path: String, // TODO path type
    user: String,
    group: String,
    mode: String, // TODO more abstract type?
}

#[derive(Error, Debug)]
enum VerificationError {
    #[error("Secret does not exist")]
    DoesNotExist(),
    #[error("Secret has mode {found}, expected {expected}")]
    ModeMismatch{
        expected: u32,
        found: u32,
    },
}
fn verify(secret: &Secret) -> Result<(), VerificationError> {
    let path = Path::new(&secret.path);

    if !path.exists() {
        return Err(VerificationError::DoesNotExist());
    }

    let spec_mode = u32::from_str_radix(&secret.mode, 8).unwrap();
    let metadata = fs::metadata(path).unwrap(); // Don't care about permission issues, this is supposed to be run as root
    let mode = metadata.mode() & 0o777;
    println!("{mode:o}");
    println!("{spec_mode:o}");
    if mode != spec_mode {
        return Err(VerificationError::ModeMismatch{
            expected: spec_mode,
            found: mode,
        });
    }

    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let spec_file = &args[1];

    let contents = fs::read_to_string(spec_file)
        .expect("Should have been able to read the file");
    let spec: Vec<Secret> = serde_json::from_str(&contents).unwrap();

    let results = spec.iter().map(verify); // TODO HashMap

    let mut is_err = false;
    for result in results {
        if result.is_err() {
            is_err = true;
            println!("{}", result.err().unwrap());
        }
    }

    if is_err {
        // TODO make fancy error messages using thiserror or something
        process::exit(1);
    }
}
