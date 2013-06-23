folks-addressbook
=================

Export Gnome contacts to the Alpine `.addressbook` format.

Gnome supports synchronisation of contacts via Gnome Online Accounts, so
as well as using this to export your local contacts from Evolution, you
can also use it to export your Google contacts, allowing one-way
synchronisation from GMail and Android.  Export from Microsoft Exchange
should also work (although I haven't tested it), and hopefully other
back-ends will become available in future.

To run, simply enter the following:

```bash
cp ~/.addressbook ~/.addressbook~ && ./folks-addressbook.vala
```

To pull in the required dependencies on Fedora, run:

```bash
sudo yum install folks-devel
```
