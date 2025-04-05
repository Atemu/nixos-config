use std::env;
use std::fs;
use std::process;
mod domain;
use adapter::spec::SpecData;
use domain::secret::verify_group;
use domain::secret::verify_mode;
use domain::secret::verify_owner;
mod adapter;
use domain::secret::SecretSpec;

fn main() {
    let args: Vec<String> = env::args().collect();
    let spec_file = &args[1];

    let contents = fs::read_to_string(spec_file).expect("Should have been able to read the file");
    let data: SpecData = serde_json::from_str(&contents).expect("Could not parse JSON");
    let spec: SecretSpec = data.to_secret_spec().expect("Could not convert data"); // TODO better error message

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

        let group_result = verify_group(&secret);
        if group_result.is_err() {
            is_err = true;
            print!(
                "Secret '{name}' at '{}' has wrong group: ",
                secret.path.display()
            );
            println!("{}.", group_result.err().unwrap());
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
