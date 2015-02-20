# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


user_kevin_cool = User.create! username: 'kevincool', email: 'kevin.cool@example.com', password: 'qwe123qwe', password_confirmation: 'qwe123qwe'
user_lukas = User.create! username: 'lukasni', email: 'lukas.ni@gnome.com', password: 'qwe123qwe', password_confirmation: 'qwe123qwe'

rc1 = ResearchCase.create! title: 'SAP Monthly Report', title: 'Queries for the monthly report'
rc1.contributers << user_kevin_cool
rc1.contributers << user_lukas

rc2 = ResearchCase.create! title: 'Towards Social Gamification Paper Data', title: 'Towards Social Gamification Paper Data'
rc2.contributers << user_kevin_cool
rc2.contributers << user_lukas

# rc3 = ResearchCase.create! title: 'Investigating the student\'s performance within and...', title: 'Investigating the student\'s performance within and...'
# rc3.contributers << user_kevin_cool

rc4 = ResearchCase.create! title: 'Daniel Master\'s Thesis: Usability Study', title: 'Usability Study'
rc4.contributers << user_lukas