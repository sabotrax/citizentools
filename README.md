# Citizentools
## API for the Star Citizen MMO

### What it is

Citizentools is an API to access information about players
and their organisations in the Star Citizen MMO.

### Documentation

The API documentation has been created with the sublime Slate.
It's [here](https://sabotrax.github.io/slate).

### Getting things up and running for development

(Provided you have a Ruby environment. If not, look [here](https://cbednarski.com/articles/installing-ruby/).)

* After cloning the repository you might want to install the necessary Gems:

  `bundle install`

* Create the log directory:

  `mkdir log`

* Fire up the API server:

  `./server`

* Run some tests:

  `ruby test.rb`

* Access the API in your favorite browser:

  http://localhost:4567/api/v2/citizen/croberts68 (WEBrick is listening on 0.0.0.0 too.)

### Installing production-ready

* You need to install an application server like [Phusion Passenger](https://www.phusionpassenger.com/library/).
* Configure your web server like I did for Apache:

  `PassengerRuby /your/ruby/interpreter/normally/called/ruby`  
  `Alias /ct /your/static/content/called/public`  
  `<Location /ct>`  
  `PassengerBaseURI /ct`  
  `PassengerAppRoot /your/app/path`  
  `</Location>`  
  `<Directory /your/static/content/called/public>`  
  `Allow from all`  
  `Options -MultiViews`  
  `Require all granted`  
  `</Directory>`

  Note that with **<Location /ct>** your URL changes from **http://host/api/v2/endpoint** to **http://host/ct/api/v2/endpoint**.

### Remark
I tend to mix English and German language throughout the project.
Sorry for that.
