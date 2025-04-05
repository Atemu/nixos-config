use std::{fmt::Display, num::ParseIntError};

#[derive(Debug, PartialEq, Clone, Copy)]
pub struct Mode {
    value: u32,
}
impl Mode {
    pub fn from_u32(value: u32) -> Self {
        Mode {
            value: value & 0o777,
        }
    }
    pub fn from_string(string: &String) -> Result<Self, ParseIntError> {
        let value = u32::from_str_radix(&string, 8)?;
        Ok(Self::from_u32(value))
    }
}
impl Display for Mode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:o}", self.value)
    }
}
