use std::fs;
use std::path::PathBuf;
use std::process;
mod domain;
use adapter::spec::SpecData;
use domain::secret::verify_group;
use domain::secret::verify_mode;
use domain::secret::verify_owner;
mod adapter;
use clap::Parser;
use domain::secret::SecretSpec;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(
        help = "The path to the JSON specification of the secrets to be verified"
    )]
    spec_path: PathBuf,

    // Whether to print good files too
    #[arg(
        short,
        long,
        default_value_t = false,
        help = "Whether to print secrets that verified successfully rather than only the errors"
    )]
    print_good: bool,
}

fn main() {
    let args = Args::parse();
    let contents =
        fs::read_to_string(args.spec_path).expect("Should have been able to read the spec file");
    let data: SpecData = serde_json::from_str(&contents).expect("Could not parse spec file JSON");
    let spec: SecretSpec = data
        .to_secret_spec()
        .expect("Could not convert data, do the users and groups actually exist?");

    let mut any_err = false;
    for (name, secret) in spec {
        let mut is_err = false;

        if !secret.path.exists() {
            any_err = true;
            println!(
                "Secret '{name}' does not exist at '{}'.",
                secret.path.display()
            );
            // We can't do any of the other checks if it doesn't exist
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
            if args.print_good {
                println!("Secret '{name}' at '{}' is correct.", secret.path.display());
            }
        }
    }

    if any_err {
        process::exit(1);
    }
}
