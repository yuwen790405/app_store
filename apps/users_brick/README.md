Users Brick
==========
This brick provides seamless user synchronization with your domain and/or project. It provides several modes of operations that suits several scenarios which we will explore below.

## Key Features:
From a high level perspective this brick can do for you

- Add users to domain
- Add/remove users to/from project
- Update user contact information
- Update user roles in a project

## Important terms

### Organization
In context of this document organization is a cache of users. User has to be created on the platform before he is added to the project and there are 2 ways. Either he registers himself/herself or he is added to an organization. User's existence in organization means only that he can log to the platform. He cannot see any project if he is explicitly not invited. Every organization has an organization admin. This admin can change users in his organization as he sees fit without users' consent.

### Project
Project is a place where data reside. User can be invited to a project which allows him to perform certain operations according to his role(s).

### Role
Set of permissions of a particular user in a given project. Example is 'can_invite_users'.

## What you need to get started:
- The domain of the project

## How things work

Let's describe all the pieces that we need to understand and then have a look at how the brick pieces things together.

## Adding users to organization

So we can add users to project later we have to add the to organization first. As stated previously organization contains information about users, their name, login, password etc. Organization is not connected to any project and the fact that a user is in a domain does not result in ability to access any project or data for him. Only organization admin can access the domain.

The way domain updates work is that all the users that you provided in the input file are added to the domain. If they are already in they are updated accordingly. The update affects only the fields you provided. If you did not provide specific field it will not be touched. To illustrate let's see an example

![Updating user in organization](https://photos-2.dropbox.com/t/2/AABPuW2tfkRhva17wTvAagmuN_H-5rQz78hGEyFeB0HrJg/12/125832525/png/1024x768/3/1425520800/0/2/updating_user_in_org.png/CM2agDwgASACIAMoAQ/hqD1ZBz1DMProyCxvggT5ocfrV9cAZ4PN7JsCH8awp4)

Notice that while john's email was updated his first name was not.

### Notes
* you do not have to (and it is a good idea not to) provide a password. If not provided it is automatically generated when created for the first time and user can either change it later or he can be set up with a SingleSignOn.
* login has to have a format of an email address
* login cannot be changed and it is used to lookup a specific user
* if specific email address is not provided login is used instead

## Adding/changing/removing users to/from project

Having discussed adding users to organization. Let's discuss the same process with project. This works completely differently so let's dig deeper.

Syncing with project process is taking a list of users as an input. Each line of this list contains three pieces of information in some form. Which user and what role should be added to project. The file is declaring how the project should end up looking at the end of the process.

* Users that are in the project but not the file will end up being removed
* Users that are in the file but not in the project are added
* Users having different role are updated

To illustrate what is happening let's have a look at this picture.

![Syncing users into project](https://photos-4.dropbox.com/t/2/AACbjGcZFHep434dDoAnsp3LtWHCHRD6xCBzzqcZcDe9_A/12/125832525/png/1024x768/3/1425520800/0/2/project_sync.png/CM2agDwgASACIAMoAQ/0qqREh5S0KWflyHFqG5zPAmhCdmidnhIckovVillHwY)

The file is on the far left. The project and its current data are in the middle. We take these to and identify several groups of users.

* Those that should be added because they are in the data coming from ETL but they are not in the project (todd@eample.com)
* Those that should be removed because they are in project but they are not in the data coming from ETL (seth@example.com)
* Those that exist in both but have different role and that has to updated (jane@example.com)
* Those that are identical in both and we do not have to touch them (john@example.com)

### Why declarative and not additive

Let me explain shortly why we decided to go the declarative ('give me how the project should look like and I will make it so') way as opposed to additive ('let me know each day who to add and remove'). The benefit of being declarative is the fact that it is idempotent and it is stateless. If I give you the full file every day you know where you will end up regardless of how the project looks like right now. Even if you run things several times you end up in the same spot. If I give you an increment where you end up is dependent on the state of the project. If something goes wrong you probably have to get the full state. Thanks to this the declarative way is also self healing. If you make a mistake one day it is going to fix itself automatically when you fix the data.

If the source system can provide only incremental data you have to do the extra work in your stateful ETL to provide a complete snapshot of the system (as you have to do  for other parts as well). Taking data from an intermediary storage has also another benefit is that you own the data you were using to perform the tasks.

## Modes of synchronization

The brick can operate in different modes. We implemented several modes that we find useful in our day to day usage. If something that would be useful for you is not here let us know the list is not meant to be definitive.

### Sync organization
The process takes a file synchronizes the organization. That is it.

### Sync project
The process takes a file and synchronizes the project. That is it.

### Sync organization and project in one go
The process takes a file synchronizes the organization and the goes forward to synchronize users in the project. The intended usage for this mode is a customer who has one project so there is no benefit in splitting the organization and project synchronization into 2 tasks. You can achieve the same effect by using 2 processes in a series. First syncing the organization and the second syncing the project.

### Sync many projects in one process
There are occasions where someone is maintaining an application with several projects. There are couple of projects like 10 or so. This mode allows a process to sync those projects all in one go. The file has to contain and additional information about what user should go to which project. The file is partitioned based on this information and each partition is used to sync a give project. The project information has to be provided in a form of Project ID (aka pid, project hash).

![One to many sync in one process](https://photos-4.dropbox.com/t/2/AABrsND21GkvFEGFsWP8WcxsQ7SRDTVSuC8D1U-I_3ebFg/12/125832525/png/1024x768/3/1425585600/0/2/project_sync_mode_on_to_many.png/CM2agDwgASACIAMoAQ/HN93Vo6AlTPfuMs9BcpqUzYDXGLvfbmSOA90ToqEf6k)

This mode is meant for cases where a person is by hand managing small number of projects so having one process distributing the users allows him to have more manageable ETL. If you are in the Powered by GoodData and automating your deployment this is probably not your best bet and you should consider one of the following.

### Sync one project filtering based on project Id
In many cases you want the same thing as in previous case. You have one source of data and you would like to each project to use just a subset. It is incovenient to prepare N different data files or N tables. How this mode differs from the previous mode is that each proejct has one process deployed and the process is responsible for filtering the data for that particular project and update just that one project (as opposed to update all projects in the previous case).

The benefit here is that the process is deployed in each project so you have everything in one place and can orchestrate things easily using administration console. The problem with having many more processes and juggling with them is mitigated by the fact that Powered by GoodData applications are usually deployed automatically. Also if you remove a project all the ETL processes are removed with it so you do not have to consider any cleanup steps.


![One to many in PBG](https://www.dropbox.com/s/m0uzv3r4zwtq682/project_sync_mode_on_to_many_pbg.png?dl=0&raw=1)

### Parameters

There are only couple of things you have to configure. For the rest sensible defaults are provided and you an override them if you need to. What you have to specify is the following


#### Required parameters
* file with the input data
* name of domain

#### Defaults
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



