# Tienda-DSS

Tasks to do

- Review the documentation and plan the app --> 1 hour
- Setup the initial config of project --> 1 hour
- Make unit test of the features to develop --> 2 hours
- Code the solution and make the test pass --> 3 hours
- User test  --> 1 hour
- Deploy proccess --> 1 hour

Update 4-oct-2020
Completed task with real time spended
- Review the documentation and plan the app --> 1.5 hour
- Setup the initial config of project --> 1 hour
- Make unit test of the features to develop --> 2.5 hours
- Code the solution and make the test pass --> 4 hours
- User test  --> 15 mins

Task to do
- Add styles and make mini store beautiful --> 2
- Deploy proccess --> 1 hour

## Description

This project represents a mini store with a pay platform integration

This are developed with:

* Ruby version 2.6.6
* Rails version 6.0.3.3

The project uses docker and docker-compose for development environment
* The Docker version used is 19.03.13
* The Docker compose version is 1.23.2

Docker compose is used to orchestrate the web/rails service and postgres service

## Configuration

### Initial setup
* In order to do the initial setup run the follow command
```bash
sudo docker-compose run web bundle exec bundle install
```

### Database setup
* In order to create a database you can run the follow command
```bash
sudo docker-compose run web bundle exec rails db:create
```

* Then run
```bash
sudo docker-compose run web bundle exec rails db:migrate
```
* The project does not have a seed to populate the initial db, although is possibly to add it

### Setup local server
You only need execute
```bash
sudo docker-compose up
```

## Unit Test
The project uses RSpec to create and run unit test
* To execute test suite run
```bash
sudo docker-compose run web bundle exec rspec spec/
```
