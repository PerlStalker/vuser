#! /usr/bin/perl -w

#use SOAP::Lite;

# Didn't work when I called a non-existant method.  Not sure why.
use SOAP::Lite 
  on_fault => sub { my( $soap, $res ) = @_; die ref $res ? $res->faultdetail : $soap->transport->status, "\n" };

# Connect to CGI server
# Doesn't handle errors.  If a fault occurs, it just prints empty string.
#print SOAP::Lite
#  -> uri( 'http://localhost/VUserSOAP/' )
#  -> proxy( 'http://localhost/soapdemo/soapcgi.pl' )
#  -> hi()
#  -> result;

# Connect to Daemon
# Doesn't handle errors.  If a fault occurs, it just prints empty string.
print SOAP::Lite
  -> uri( 'http://localhost:8080/VUser/SOAP' )
  -> proxy( 'http://localhost:8080/' )
  -> hi()
  -> result;

print SOAP::Lite
  -> uri( 'http://localhost:8080/VUser/SOAP' )
  -> proxy( 'http://localhost:8080/' )
  -> CORE_version()
  -> result;
