#!/usr/bin/vala -X -w --pkg gtk+-3.0 --pkg folks --pkg gee-0.8

//     Copyright 2013 Peter Oliver.
//
//     This file is part of folks-addressbook.
//
//     folks-addressbook is free software: you can redistribute it
//     and/or modify it under the terms of the GNU General Public
//     License as published by the Free Software Foundation, either
//     version 3 of the License, or (at your option) any later version.
//
//     folks-addressbook is distributed in the hope that it will be
//     useful, but WITHOUT ANY WARRANTY; without even the implied
//     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//     See the GNU General Public License for more details.
//
//     You should have received a copy of the GNU General Public License
//     along with folks-addressbook.  If not, see
//     <http://www.gnu.org/licenses/>.

using Gtk;
using Folks;
using Gee;

int main(string[] args) {
	Gtk.init(ref args);
	
	var aggregator = new Folks.IndividualAggregator();
	var nicknames = new HashSet<string> ();
	
	aggregator.notify["is-quiescent"].connect(
		(agg, evt) => {
			var people = new Gee.LinkedList<Person> ();

			foreach ( var individual in aggregator.individuals.values ) {
				var primary_email = primary_address_for_individual(individual);
				if ( primary_email == null ) { continue; }

				string sortname = sortname_for_individual(individual);
				string nickname = ( individual.alias != ""
									? individual.alias : individual.nickname );
				
				// FIXME: how to make this stable?
				if ( nickname != "" && nicknames.contains(nickname) ) {
					int i = 2;
					while ( nicknames.contains("%s%d".printf(nickname, i)) ) {
						++i;
					}
					nickname = "%s%d".printf(nickname, i);
				}
				nicknames.add(nickname);

				people.add(
					new Person(nickname, sortname, primary_email, individual)
				);

			}

			CompareDataFunc<Person> compare_individuals = (a, b) => {
				return strcmp(a.sortname, b.sortname);
			};
			people.sort(compare_individuals);
			foreach ( var person in people ) {
				// Output the primary email address:
				print_contact(
					person.nickname,
					person.sortname,
					person.primary_email
				);

				// ...and any additional addresses:
				int i = 1;
				foreach ( var email in person.individual.email_addresses ) {
					if ( email == person.primary_email ) { continue; }
					print_contact(
						( person.nickname == "" 
						  ? "" : "%s.%d".printf(person.nickname, i++) ),
						person.sortname, 
						email
					);
				}
			}

			Gtk.main_quit();
		}
	);

	aggregator.prepare.begin();
	Gtk.main();
	return 0;
}

void print_contact(
	string nickname, string sortname, EmailFieldDetails email
) {
	var delimiters = new Regex("[\t\n]");
	var whitespace = new Regex("\\s");

	string types = string.joinv(" ", email.parameters.get("type").to_array());

	stdout.printf(
		"%s\t%s\t%s\t\t%s\n",
		whitespace.replace(nickname, -1, 0, ""),
		delimiters.replace(sortname, -1, 0, ""),
		// FIXME: escape these properly:
		delimiters.replace(email.value, -1, 0, ""),
		delimiters.replace(types, -1, 0, "")
	);
}

string sortname_for_individual(Folks.Individual individual) {
	if ( individual.structured_name == null ) {
		return "";
	}
	else if ( individual.structured_name.given_name != null 
			  && individual.structured_name.given_name != ""
			  && individual.structured_name.family_name != null
			  && individual.structured_name.family_name != "" ) {
		return "%s, %s".printf(individual.structured_name.family_name,
							   individual.structured_name.given_name);
	}
	else if ( individual.structured_name.family_name != null
			  && individual.structured_name.family_name != "" ) {
		return individual.structured_name.family_name;
	}
	else if ( individual.structured_name.given_name != null 
			  && individual.structured_name.given_name != "") {
		return individual.structured_name.given_name;
	}

	// FIXME: get name from company, etc.?

	return "";
}

EmailFieldDetails primary_address_for_individual(Folks.Individual individual) {
	foreach ( var address in individual.email_addresses ) {
		foreach ( string value 
				  in address.parameters.get("x-evolution-ui-slot") ) {
			if ( value == "1" ) {
				return address;
			}
		}
	}
	foreach ( var address in individual.email_addresses ) {
		return address;
	}
	return null;
}

class Person {
	public string nickname;
	public string sortname;
	public EmailFieldDetails primary_email;
	public Individual individual;

	public Person(
		string nickname,
		string sortname,
		EmailFieldDetails primary_email,
		Individual individual
	) {
		this.nickname = nickname;
		this.sortname = sortname;
		this.primary_email = primary_email;
		this.individual = individual;
	}
}
