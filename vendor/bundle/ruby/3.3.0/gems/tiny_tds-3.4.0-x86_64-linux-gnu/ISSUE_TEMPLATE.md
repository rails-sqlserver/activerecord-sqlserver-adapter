## Before submitting an issue please check these first!

* On Windows? If so, do you need devkit for your ruby install?
* Using Ubuntu? If so, you may have forgotten to install FreeTDS first.
* Are you using FreeTDS 1.0.0 or later? Check `$ tsql -C` to find out.
* If not, please update then uninstall the TinyTDS gem and re-install it.
* Have you made sure to [enable SQL Server authentication](http://bit.ly/1Kw3set)?
* Doing work with threads and the raw client? Use the ConnectionPool gem?

If none of these help. Please fill out the following:

## Environment

**Operating System**

Please describe your operating system and version here.
If unsure please try the following from the command line:

* For Windows: `systeminfo | findstr /C:OS`
* For Linux: `lsb_release -a; uname -a`
* For Mac OSX: `sw_vers`

**TinyTDS Version and Information**

```
Please paste the full output of `ttds-tsql -C` (or `tsql -C` for older versions
of TinyTDS) here. If TinyTDS does not install, please provide the gem version.
```


**FreeTDS Version**

Please provide your system's FreeTDS version. If you are using the pre-compiled
windows gem you may omit this section.

## Description

Please describe the bug or feature request here.
