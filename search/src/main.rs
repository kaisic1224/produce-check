use std::{fs, env, time::{SystemTime, UNIX_EPOCH}, error::Error};

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();
    let file_path = "/home/vincent/Desktop/datalogs/script/diffs.csv";
    let file = fs::read(file_path).unwrap();
    let (res, _, _) = encoding_rs::SHIFT_JIS.decode(&file);

    let mut reader = csv::ReaderBuilder::new()
        .flexible(true)
        .from_reader(res.as_bytes());
    let mut writer = csv::WriterBuilder::new()
        .flexible(true)
        .from_path(file_path)?;

    // write headers first
    writer.write_record(["file","words","difference","last_changed"])?;
    
    let mut found = false;
    for result in reader.records() {
        let record  = result?;
        if record[0] == args[1] {
            let difference = args[2].parse::<i32>().unwrap() - record[1].parse::<i32>().unwrap();
            writer.write_record([&record[0], &args[2], difference.to_string().as_str(), SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs().to_string().as_str()])?;
            println!("{}", difference);
            found = true
        } else {
            writer.write_record(&record)?;
        } 
    } 
    if !found {
        writer.write_record([&args[1], &args[2], &"0".to_string(), &SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs().to_string()])?;
    }


    writer.flush()?;
    Ok(())
}
