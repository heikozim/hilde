use clap::{Arg, ArgAction, Command};

fn main() {
    let matches = Command::new("pack")
        .about("A small archive tool.")
        .version("0.2")
        .subcommand_required(true)
        .arg(
            Arg::new("verbose")
                .short('v')
                .long("verbose")
                .help("More output")
                .action(ArgAction::Count)
                .global(true),
        )
        .subcommand(
            Command::new("add")
                .about("Add files.")
                .alias("a")
                .arg(
                    Arg::new("force")
                        .short('f')
                        .long("force")
                        .help("Overwrite what is there")
                        .action(ArgAction::SetTrue),
                )
                .arg(
                    Arg::new("file")
                        .help("Files to add")
                        .required(true)
                        .num_args(1..),
                ),
        )
        .subcommand(
            Command::new("list").about("List the archive.").arg(
                Arg::new("long")
                    .short('l')
                    .long("long")
                    .help("One line each")
                    .action(ArgAction::SetTrue),
            ),
        )
        .get_matches();

    match matches.subcommand() {
        Some(("add", sub)) => {
            println!("verbose: {}", sub.get_count("verbose"));
            println!("add, force: {}", sub.get_flag("force") as u8);
            for file in sub.get_many::<String>("file").unwrap() {
                println!("  file: {file}");
            }
        }
        Some(("list", sub)) => {
            println!("verbose: {}", sub.get_count("verbose"));
            println!("list, long: {}", sub.get_flag("long") as u8);
        }
        _ => unreachable!(),
    }
}
