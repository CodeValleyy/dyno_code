use crate::types::{ExecutionPayload, ExecutionResult};
use std::process::{Command, Stdio};
use std::io::{Write, Error};
use tempfile::NamedTempFile;

pub struct SimpleExecutor;

impl SimpleExecutor {
    pub fn execute(payload: &ExecutionPayload) -> ExecutionResult {
        let output = match payload.language.as_str() {
            "python" => Command::new("python3")
                .arg("-c")
                .arg(&payload.code)
                .output(),
            "lua" => Command::new("lua")
                .arg("-e")
                .arg(&payload.code)
                .output(),
            "rust" => Self::compile_and_run_rust_code(&payload.code),
            _ => Err(Error::new(std::io::ErrorKind::Other, "Language not supported")),
        };

        match output {
            Ok(output) => {
                ExecutionResult {
                    output: String::from_utf8_lossy(&output.stdout).to_string(),
                    error: String::from_utf8_lossy(&output.stderr).to_string(),
                }
            },
            Err(e) => ExecutionResult {
                output: "".to_string(),
                error: e.to_string(),
            },
        }
    }

    fn compile_and_run_rust_code(code: &str) -> std::io::Result<std::process::Output> {
        let mut temp_file = NamedTempFile::new()?;
        writeln!(temp_file, "{}", code)?;

        let crate_name = "temp_crate";
        let binary_path = temp_file.path().with_extension("exe");

        let compile_output = Command::new("rustc")
            .arg(temp_file.path())
            .arg("-o")
            .arg(&binary_path)
            .arg("--crate-name")
            .arg(crate_name)
            .output()?;

        if compile_output.status.success() {
            Command::new(binary_path).output()
        } else {
            Ok(compile_output)
        }
    }
}