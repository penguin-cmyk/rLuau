local Handler = require("./helpers/handler.luau")
print(Handler.translate([[
fn x() {
    println!("YESSS")   
}
]]))