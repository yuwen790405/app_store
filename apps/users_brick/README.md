Users Brick
==========
This brick provides no seamless user synchronization with your domain and/or project.

Managing user roles in projects is a complicated problem. This ruby brick allows you to automatically ensure your project's users stay up to date. Using a CSV document or a specific set of columns as a single point-of-truth the brick will update and change the project to match the document.

## Key Features:
- Add users to domain
- Add/remove users to/from project
- Update user contact information
- Move users easily between projects
- No programming is required to maintain this brick
- Update user roles in a project

This brick in particular was built to allow you to deploy once and never have to think about it again. 

## What you need to get started:
- The domain of the project
- A CSV file containing the user names, first and last name, password, role, and optionally email


## Example data
To better illustrate what is going to happen we will use these test data

email | login | first_name | last_name | role
------|-------|------------|-----------|------
tomas@gooddata.com | tomas@gooddata.com | Tomas | Svarovsky | admin
patrick@gooddata.com | patrick@gooddata.com | Patrick | McConlogue | viewer
mark@tatooine.com | mark@tatooine.com | Mark | Hamil | viewer

Note that we will be using the same file for driving both examples domain and project. Not all information is used in each (role is not used when adding users to domain for example) but this approach is preferred so you do not have to prepare specific files for each run.

## Adding users to domain

So we can add users to project later automatically without users' consent we have to add them to domain first. Domain (also sometimes called organization) can be obtained by contacting GoodData support. Domain contains information about users, their name login, password etc. Domain is not connected to any project and the fact that a user is in a domain does not result in ability to access any project or data for him.

The way domain updates work is that all the users that you provided in the input file are added to the domain. If they are already in they are updated accordingly.

### Notes
* you do not have to provide a password. If not provided it is automatically generated and user can either change it later or he can be set up with a SingleSignOn.
* login has to have a format of an email address
* if specific email address is not provided login is used instead

### How to run

There are only couple of things you have to configure. For the rest sensible defaults are provided and you an override them if you need to. What you have to specify is the following

* file with the input data
* name of domain

The following list contains the properties that are useful to specify for updating a domain. The name after hyphen is the default. In parenthesis you can find name of the parameter you can use to override the default.

* First name - first_name (first_name_column)
* Last name - last_name (last_name_column)
* Login - login (login_column)
* Password - password (password_column)
* Email - email (email_column)
* SSO Provider - sso_provider (sso_provider_column)

For instance, if in your data first names would be stored in a column called "users_first_names", you would pass the params file: 

    {
        :first_name_column => "users_first_names"
    }


As mentioned previously only login is really required all other columns will be provided with defaults if not specified.

## Runtime Notes
- If no email is provided, the login is used in used in it's place.
- Roles are resolved by their identifier ("adminRole"), you can view the complete list [User Roles](https://support.gooddata.com/entries/23297728-User-Roles-Overview)
- Users not found in the CSV will be removed.





