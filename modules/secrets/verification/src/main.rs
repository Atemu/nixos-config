use serde::{Deserialize, Serialize};
use std::env;
use std::fs;
use std::process;
use std::path::Path;

#[derive(Serialize, Deserialize, Debug)]
struct Secret {
    path: String, // TODO path type
    user: String,
    group: String,
    mode: String, // TODO more abstract type?
}

enum VerificationError {
    FileDoesNotExist(),
}
fn verify(secret: &Secret) -> Result<(), VerificationError> {
    let path = Path::new(&secret.path);

    if !path.exists() {
        return Err(VerificationError::FileDoesNotExist());
    }

    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let spec_file = &args[1];

    let contents = fs::read_to_string(spec_file)
        .expect("Should have been able to read the file");
    let spec: Vec<Secret> = serde_json::from_str(&contents).unwrap();
    println!("{:?}", spec);

    let mut result = spec.iter().map(verify);

    if result.any(|it| it.is_err()) {
        // TODO make fancy error messages using thiserror or something
        println!("Bad!");
        process::exit(1);
    }
}
