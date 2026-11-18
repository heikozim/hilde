use clap::builder::BoolishValueParser;
use clap::{value_parser, Arg, ArgAction, Command};

fn main() {
    let matches = Command::new("greet")
        .about("Prints a greeting.")
        .version("1.0")
        .arg(
            Arg::new("name")
                .short('n')
                .long("name")
                .value_name("NAME")
                .help("Who to greet")
                .default_value("world"),
        )
        .arg(
            Arg::new("times")
                .short('t')
                .long("times")
                .help("How often")
                .value_parser(value_parser!(i64).range(1..=5))
                .default_value("1"),
        )
        .arg(
            Arg::new("polite")
                .long("polite")
                .help("Say please")
                .value_parser(BoolishValueParser::new())
                .default_value("false"),
        )
        .arg(
            Arg::new("loud")
                .short('l')
                .long("loud")
                .help("Shout")
                .action(ArgAction::SetTrue),
        )
        .get_matches();

    let name = matches.get_one::<String>("name").unwrap();
    let times = matches.get_one::<i64>("times").unwrap();
    let end = if matches.get_flag("loud") { "!" } else { "." };
    println!("Hello, {name}{end}");
    println!("times: {times}");
    println!("polite: {}", matches.get_one::<bool>("polite").unwrap());
}
