#!/usr/bin/vala --pkg gtk+-3.0 --pkg folks

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

int main(string[] args) {
	Gtk.init(ref args);
	
	var aggregator = new Folks.IndividualAggregator();
	
	aggregator.notify["is-quiescent"].connect(
		(agg, evt) => {
			stdout.printf("called back.\n");
			foreach ( var individual in aggregator.individuals.values ) {
				var nickname = nickname_for_individual(individual);
				var sortname = sortname_for_individual(individual);
				var address = primary_address_for_individual(individual);
				if ( address == "" ) { continue; }

				// FIXME: add a separate row for each address found?
				stdout.printf("%s\t%s\t<%s>\n", nickname, sortname, address);
			}

			Gtk.main_quit();
		}
	);

	aggregator.prepare();
	Gtk.main();
	return 0;
}

// FIXME: need to ensure returned value is unique to the invididual.
// FIXME: strip whitespace.
string nickname_for_individual(Folks.Individual individual) {
	if ( individual.nickname != "" ) {
		return individual.nickname;
	}

	string nickname = ""; 
	// FIXME: what is the Vala syntax to make this a loop?
	if ( individual.structured_name.given_name != null ) {
		nickname += individual.structured_name.given_name;
	}
	if ( individual.structured_name.family_name != null ) {
		nickname += individual.structured_name.family_name;
	}

	return nickname;
}

string sortname_for_individual(Folks.Individual individual) {
	if ( individual.structured_name.given_name != null 
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

string primary_address_for_individual(Folks.Individual individual) {
	foreach ( var address in individual.email_addresses ) {
		foreach ( var value in address.parameters.get("x-evolution-ui-slot") ) {
			if ( value == "1" ) {
				return address.value;
			}
		}
	}
	foreach ( var address in individual.email_addresses ) {
		return address.value;
	}
	return "";
}