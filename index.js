const express = require("express");
const bodyParser = require("body-parser");
const handlebars = require("express-handlebars");
const mysqlConnection = require("./mysql.js");

const port = 3000;
const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.set("view engine", "hbs");

app.engine("hbs", handlebars.engine({
    layoutsDir: __dirname+'/views/layouts',
    extname: "hbs",
    helpers: require('./helper')
}));


app.use(express.static("public"));

// Home Page -- GET
app.get('/', (req, res, next)=>{
    res.render("main", {layout: "index", title:"Home Page"});
})

// Register Page -- GET
app.get('/register', (req, res, next)=>{
    res.render("register", {layout: "index", title:"Register"});
})

// Login Page -- GET
app.get('/login', (req, res, next)=>{
    res.render("login", {layout:"index", title:"Login"});
})
// Login Page --POST
app.post('/login', async (req, res, next)=>{
    var body = req.body;
    var username = body.username;
    var password = body.password;
    var sql = `SELECT attendeeLogin("${username}", "${password}") AS auth;`;
    [results, fields] = await mysqlConnection.execute(sql);
    if (!results[0]["auth"]){
        res.render("login", {layout: "index", title:"Login", error:"Please enter correct Username and Password"});
    }else{
        res.redirect("/userProfile?username="+username);
    }
})
// UserProfile Page --GET
app.get("/userProfile",async (req, res, next)=>{
    var username = req.query.username;
    var attendeeDetailSQL = `CALL getUserDetails("${username}");`
    var [userDetails, fields] = await mysqlConnection.execute(attendeeDetailSQL);

    var ticketPurchasedByAttendeeSQL = `CALL ticketPurchasedByAttendee("${username}");`
    var [ticketsPurchased,_] = await mysqlConnection.execute(ticketPurchasedByAttendeeSQL);

    var ticketsPurchasedResolved = [];
    ticketsPurchased[0].forEach((ticket)=>{
        var found =0;
        ticketsPurchasedResolved.forEach((ticketRes)=>{
            if (ticket.event_id == ticketRes.event_id){
                ticketRes.performers.push(ticket.performer_name);
                found = 1;
            }
        })
        if (!found){
            var dict = {
                "event_id":ticket.event_id,
                "event_name":ticket.name,
                "description": ticket.description,
                "date_time": ticket.date_time,
                "location":ticket.location,
                "Q_order":ticket.Q_order,
                "Q_used":ticket.Q_used,
                "performers":[ticket.performer_name],
            };
            ticketsPurchasedResolved.push(dict);
        }
    })

    var itemPurchassedByAttendeeSQL = `CALL itemPurchasedByAttendee("${username}");`
    var [itemsPurchased,_] = await mysqlConnection.execute(itemPurchassedByAttendeeSQL);

    var ticketAvailableForSaleSQL = `CALL TicketAvailableForSale();`;
    var [ticketsAvailable, _] = await mysqlConnection.execute(ticketAvailableForSaleSQL);

    var ticketsAvailableResolved = [];
    ticketsAvailable[0].forEach((ticket)=>{
        var found =0;
        ticketsAvailableResolved.forEach((ticketRes)=>{
            if (ticket.event_id == ticketRes.event_id){
                ticketRes.performers.push(ticket.performer_name);
                found = 1;
            }
        })
        if (!found){
            var dict = {
                "event_id":ticket.event_id,
                "event_name":ticket.event_name,
                "description": ticket.description,
                "date_time": ticket.date_time,
                "capacity_left":ticket.capacity_left,
                "location":ticket.location,
                "duration":ticket.duration,
                "price":ticket.price,
                "performers":[ticket.performer_name],
            };
            ticketsAvailableResolved.push(dict);
        }
    })

    var itemAvailableForSaleSQL = `CALL itemAvailableForSale();`;
    var [itemsAvailable, _] = await mysqlConnection.execute(itemAvailableForSaleSQL);

    res.render("userProfile", {
        layout:"index", 
        title:"UserProfile", 
        username:username,
        userDetails:userDetails[0][0], 
        ticketsPurchased: ticketsPurchasedResolved,
        itemsPurchased: itemsPurchased[0],
        ticketsAvailable: ticketsAvailableResolved,
        itemsAvailable:itemsAvailable[0],
    });
})
// Purchase Ticket --POST
// TODO find a way to incorporate banner
app.post("/purchaseTicket", async function(req, res, next) {
    var username = req.body.username;
    var event_id = req.body.event_id;

    var purchaseTicketSQL = `CALL purchase_ticket("${username}", ${event_id}, 1, @status);`;
    var q2 =  "SELECT @status";
    await mysqlConnection.execute(purchaseTicketSQL);
    var [response, fields, error] = await mysqlConnection.execute(q2);
    
    if (!response[0]["status"]){
        res.redirect(`/userprofile/?username=${username}`);
    }else{
        res.redirect("/userProfile?username="+username);
    }

})
// Purchase Item --POST
app.post("/purchaseItem", async function(req, res, next) {
    var username = req.body.username;
    var item_id = req.body.item_id;

    var purchaseItemSQL = `CALL purchase_item(${item_id}, 1,"${username}", @status);`;
    var q2 =  "SELECT @status;";
    await mysqlConnection.execute(purchaseItemSQL);
    var [response, fields, error] = await mysqlConnection.execute(q2);
    
    if (!response[0]["response"]){
        res.redirect(`/userprofile/?username=${username}`);
    }else{
        res.redirect("/userProfile?username="+username);
    }

})
// ticket --POST
app.post("/ticket", async function(req, res, next) {
    var username = req.body.username;
    var event_id = req.body.event_id;

    var ticketPurchasedByAttendeeSQL = `CALL ticketPurchasedByAttendeeEvent("${username}", ${event_id});`
    var [ticketsPurchased,_] = await mysqlConnection.execute(ticketPurchasedByAttendeeSQL);
    var ticketsPurchasedResolved = [];
    ticketsPurchased[0].forEach((ticket)=>{
        var found =0;
        ticketsPurchasedResolved.forEach((ticketRes)=>{
            if (ticket.event_id == ticketRes.event_id){
                ticketRes.performers.push(ticket.performer_name);
                found = 1;
            }
        })
        if (!found){
            var dict = {
                "event_id":ticket.event_id,
                "event_name":ticket.name,
                "description": ticket.description,
                "date_time": ticket.date_time,
                "location":ticket.location,
                "Q_order":ticket.Q_order,
                "Q_used":ticket.Q_used,
                "performers":[ticket.performer_name],
            };
            ticketsPurchasedResolved.push(dict);
        }
    })
    res.render("ticket", {
        layout:"index", 
        title:"Ticket", 
        username:username,
        ticketsPurchased: ticketsPurchasedResolved[0],
    });

})
// AdminLogin --GET
app.get('/adminLogin', (req, res, next)=>{
    res.render("adminLogin", {layout:"index", title:"Admin Login"});
})
// AdminLogin --POST
app.post('/adminLogin', async (req, res, next)=>{
    var body = req.body;
    var username = body.username;
    var password = body.password;
    var sql = `SELECT adminLogin("${username}", "${password}") AS auth;`;
    [results, fields] = await mysqlConnection.execute(sql);
    if (!results[0]["auth"]){
        res.render("adminLogin", {layout: "index", title:"Admin Login", error:"Please enter correct Admin Credentials!"});
    }else{
        console.log("fasd")
        res.redirect("/adminProfile?username="+username);
    }
})
// Admin Profile --GET
app.get('/adminProfile', (req, res, next)=>{
    var adminUsername = req.query.username;

    
})

const server = app.listen(port, function(){
    console.log(`Serving FestManagement backend at port ${port}`);
})