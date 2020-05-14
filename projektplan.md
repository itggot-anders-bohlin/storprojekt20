# Projektplan

## 1. Projektbeskrivning (Beskriv vad sidan ska kunna göra)
    Jag skall göra en webshop där man kan logga in och lägga till och ta bort saker i sin kundvagn. Man ska även kunna logga in som admin och då kunna lägga till nya produkter, ändra info om existerande produkter och ta bort produkter med ett CRUD-interface. Det skall finnas entiteter i databasen med många till många kardinalitet.
## 2. Vyer (visa bildskisser på dina sidor)
     
## 3. Databas med ER-diagram (Bild)
    
## 4. Arkitektur (Beskriv filer och mappar - vad gör/inehåller de?)
    I db mappen ligger databasfilen stroprojekt.db
    I public mappen ligger min css fil, den är tom då jag inte gjort någon css
    I views mappen ligger alla slim-filer. De är uppdelade i undermapparna shop och users. I shop ligger de slim filer som visar sidor relaterade till shopen, exempelvis kundvagne i shop/show. I users finn sidor relaterade till användarna, exempelvis users/index som används för att skapa ett nytt konto. Det finns också fyra slim-filer som inte ligger i users eller shop. De är error, layout, register_confirmation och start. Error är sidan där det visas felmeddelanden om en användare gör något fel, register_confirmation är en sida för konfirmation av registrering, start är min startsida och layout är filen som får allt att fungera.
    app.rb är min controller där jag har alla routes, sessions, authorization och felhantering.
    model.rb är min model där jag har databasinteraktion, validering och authentication.