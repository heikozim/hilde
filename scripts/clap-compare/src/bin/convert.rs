use clap::{value_parser, Arg, ArgAction, Command};
use std::path::PathBuf;

fn main() {
    let matches = Command::new("convert")
        .about("Converts a file.")
        .arg(
            Arg::new("format")
                .short('f')
                .long("format")
                .help("Output format")
                .value_parser(["json", "text"])
                .env("CONVERT_FORMAT"),
        )
        .arg(
            Arg::new("jobs")
                .short('j')
                .long("jobs")
                .help("Parallel jobs")
                .value_parser(value_parser!(i64).range(1..=64))
                .env("CONVERT_JOBS")
                .default_value("1"),
        )
        .arg(
            Arg::new("quiet")
                .short('q')
                .long("quiet")
                .help("Print nothing")
                .action(ArgAction::SetTrue)
                .conflicts_with("verbose"),
        )
        .arg(
            Arg::new("verbose")
                .short('v')
                .long("verbose")
                .help("Print more")
                .action(ArgAction::SetTrue),
        )
        .arg(
            Arg::new("output")
                .short('o')
                .long("output")
                .help("Where to write")
                .value_parser(value_parser!(PathBuf))
                .requires("format"),
        )
        .arg(
            Arg::new("exclude")
                .short('x')
                .long("exclude")
                .help("Skip a name")
                .action(ArgAction::Append),
        )
        .arg(
            Arg::new("input")
                .help("The file to convert")
                .required(true)
                .value_parser(value_parser!(PathBuf)),
        )
        .get_matches();

    println!("input: {}", matches.get_one::<PathBuf>("input").unwrap().display());
    match matches.get_one::<String>("format") {
        Some(format) => println!("format: {format}"),
        None => println!("format: none"),
    }
    println!("jobs: {}", matches.get_one::<i64>("jobs").unwrap());
    match matches.get_one::<PathBuf>("output") {
        Some(output) => println!("output: {}", output.display()),
        None => println!("output: none"),
    }
    let skipped: Vec<&String> = matches
        .get_many::<String>("exclude")
        .map(|names| names.collect())
        .unwrap_or_default();
    println!("exclude: {}", skipped.len());
    for name in skipped {
        println!("  skip: {name}");
    }
    println!(
        "quiet: {}, verbose: {}",
        matches.get_flag("quiet") as u8,
        matches.get_flag("verbose") as u8
    );
}
