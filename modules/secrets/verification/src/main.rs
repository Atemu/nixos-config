use serde::{Deserialize, Serialize};
use std::env;
use std::fs;

#[derive(Serialize, Deserialize, Debug)]
struct Secret {
    path: String, // TODO path type
    user: String,
    group: String,
    mode: String, // TODO more abstract type?
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let spec_file = &args[1];

    let contents = fs::read_to_string(spec_file)
        .expect("Should have been able to read the file");
    let spec: Vec<Secret> = serde_json::from_str(&contents).unwrap();
    println!("{:?}", spec);
}
