//_______________________________________________Diverse variabler_________________________________________________________
import processing.serial.*;// Serial kobling - dette gjør at vi kan koble til arduino
import ddf.minim.*; //Minim er et bibliotek som lar oss spille ut musikk
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
import java.util.*; //Vi benytter oss av java datastruktur og syntax, forklares mer i rapport
Serial myPort;  // Skape en global port
Minim minim;   // Lage et instans av minim
AudioPlayer lydSpiller;  // Skape et instans av audioplayer (fra minim
Quiz quizzen; //instands av Quiz (klasse vi lager selv
String serielldata; //Data vi leser fra serial
String knappTilstand; //knappene sin tilstand: 1/0
int tilkoblingsForsok; //hjelpevariabel for å se antall forsøk på å koble arduino og processing
boolean poengOkt = false; //"condition" vi har for å øke poeng
boolean resett = false; //"condition" vi har for å resette poeng
int rawPoeng = 1; //poeng vi leser inn fra arduino
int poeng = 0; //poeng vi skal telle
//________________________________________________________________________________________________________________________
//________________________________________________________________________________________________________________________
//SKAPER KLASSER FOR SPØRSMÅL OG QUIZ
//________________________________________________________________________________________________________________________¨


//basisk klasse med parametre spN, sText, rSvar
class sporsmol{
  protected int sporsmolNummer;
  protected String riktigSvar;
  protected String sporsmolTekst;
  public sporsmol(int spN, String sText, String rSvar){
    sporsmolNummer = spN;
    riktigSvar = rSvar;
    sporsmolTekst = sText;
  }  
  int hentSporsmolNummer(){
    return sporsmolNummer;
  }
  String hentRiktigSvar(){
  return riktigSvar;
  }
  String hentSporsmolTekst(){ //sporsmol text er egentlig mest en hjelpevariabel som hjelper oss å følge med i serial
    return sporsmolTekst;
  }
}

//________________________________________________________________________________________________________________________
//
class Quiz{
  protected sporsmol vaaresporsmol[]; //spølrsmål vi har i quizzen 
  protected Boolean bruktesporsmol[];  //spørsmål vi har brukt opp (skal ikke brukes igjen)
  public int antFerdigeSporsmol; //antall spørsmål vi er ferdige med (brukes for å telle runder)
  protected Table table; //Processing objekt med syntax som tillater oss å lese fra csv filer, vi bruker dette for å lese en CSV fil med tilhørende egenskaper for å lese av en fil og skape spørsmål.
  protected int radAnt; //antall rader
  protected int maks; //maks antall spørsmål (kommer ann på verdiene i tabellen)
  
  Quiz(){
    
    table = loadTable ("tabell.csv", "header"); //laster inn tabellen. første parameter er navn (endre ved behov), andre er typen tabell, "header" er basic syntax.
    radAnt = table.getRowCount(); //finner ant rader
    
    println("\n\n"); //for at ting skal se finere ut i serial :)
    println("------------------------");
   
    println("Antall rader i tabell: " + radAnt + "|");
    
    //angir lengde på vaare spørsmål
    antFerdigeSporsmol = 0;
    bruktesporsmol = new Boolean[radAnt];
    for (int i = 0; i <radAnt ; i++){
      bruktesporsmol[i] = false ;
      }
     vaaresporsmol = new sporsmol[radAnt];
    }

  //LESER SPORSMÅL FRA TABELL - denne metoden gjør at man skal kunne legge til så mange filer og spørsmål man vil til tabellen så lenge man følger formatet.
  void hentSporsmolfraTable(){  
    for (int i = 0; i<radAnt; i++){ //for hver rad
      
      TableRow rad = table.getRow(i);
      
      //se på testFil.csv før du leser dette for å få en bedre forståelse av oppsettet
      
      String kolonne = ("sporsmol_nr"); //lag ny kategori for sporsmol_nr
      int sporsmolNummer = rad.getInt(kolonne); //rader under er sporsmolNummer
      
      kolonne = ("sporsmol_text"); //lag ny kategori for sporsmol_text
      String sporsmolTekst = rad.getString(kolonne); //rader under er sporsmolText
      
      kolonne = ("sporsmol_riktigAlternativ"); //lag ny kategori for sporsmol_riktigAlternativ
      String riktigSvar = rad.getString(kolonne); //rader under er riktigAlternativ
      
      if (riktigSvar.equals("") || riktigSvar.equals(" ")){ //om vi kommer til en tom rad
        println("ingen flere sporsmol");
        maks = i;
        break;
        } else maks = radAnt;
       println("Sporsmol nummer " + sporsmolNummer + " skapt |" );
       
       vaaresporsmol[i] = new sporsmol(sporsmolNummer, sporsmolTekst, riktigSvar); //setter spørsmål i arrayen
    }  
    println("Maks antall sporsmol: " +maks + " |");
    println("------------------------");
    println("________________________________________________________________________________________");
    println("|                      |                                    |                           |");
    println("|                      |         ALLE SPØRSMÅL SKAPT        |                           |");

    

  }
  
  //metode som henter et tilfeldig spørsmål, og skriver informasjon om denne.
  //brukes på starten av hver draw for å lese opp et spørsmpl
  
  int hentNesteSporsmol(){ //henter et tilfeldig sporsmol av de som er i tabellen til å bli neste
    int randomTall = int(random(0, (maks)));
    while (bruktesporsmol[randomTall] == true){
      randomTall = int(random(0, (maks-1)));
    }
    //henter og skaper en lydFil til spørsmålene
    //sporsmol filen skal ha navnene: "sporsmol_1", "sporsmol_" osv, og vi får dermed en slik kode for å lese dette inn
    String lydFilNavn = String.format("sporsmol_%s.mp3", vaaresporsmol[randomTall].hentSporsmolNummer());
    
    
    println("Tilfeldig spørsmål valgt: " + randomTall);
    println("Sporsmol nr er: " + vaaresporsmol[randomTall].hentSporsmolNummer());
    println("Spiller " + lydFilNavn + "...");
    println("------------------------------");
    println("Sporsmol tekst er: " + vaaresporsmol[randomTall].hentSporsmolTekst());
    
    println("Sporsmol svar er:  " +vaaresporsmol[randomTall].hentRiktigSvar());
    println("Poeng:" + poeng);
    println("");
    println("                          Venter på svar...... (riktig er " + vaaresporsmol[randomTall].hentRiktigSvar() + ")              ");
    println("");

    spillLyd(lydFilNavn); //bruker en egendefinert metode for å spille lydfilen.
    bruktesporsmol[randomTall] = true;
    return randomTall;
  }

  
}

//________________________________________________________________________________________________________________________
//DIVERSE  METODER
//________________________________________________________________________________________________________________________


//metode som blir brukt for å lese inn, trimme og returne seriell data.
String lesSeriellData(int dly){ //parameter delay angir hvor lenge den skal vente før den kjører på nytt, ekstremt viktig art metoden repeterer helt til den får gyldig seriell data.
  String  raaSeriellData = myPort.readStringUntil('\n');
  if (raaSeriellData != null) {  // om dataen ikke er tom, gå videre
    //trim whitespace og formater
    String serielldata = trim(raaSeriellData);
    return serielldata; 
  } else {
    delay(dly);
    return " ";
  }
}

//metode som benytter seg av minim til å spille av en lydfil
void spillLyd(String filnavn){
  lydSpiller = minim.loadFile(filnavn);
    //lydSpiller.setGain(+1.0) - tilfelle man skulle trenge å endre lyd
   lydSpiller.play(); //spil av filen fra parameter

   do{ //imens lydfilen spiller, stans programmet og vent til lydfilen er ferdig
       delay(500);
       }while (lydSpiller.isPlaying());
}



//________________________________________________________________________________________________________________________
//SETUP
//________________________________________________________________________________________________________________________




void setup(){
  
    
    minim = new Minim(this);

   printArray(Serial.list()); //avkommenter for å finne din port,
  // Vi åpner porten vi ønsker å bruke
  String portNavn = Serial.list()[3]; //vi bytter [x] med hvilken enn USB vi er koblet til, endre verdien her!!!
  myPort = new Serial(this, portNavn, 9600); //lag ny serial - viktigheten og hvordan arduino og processing kommuniserer blir detaljer i rapport, ikke hjer
  myPort.bufferUntil('\n');
      
  println("_____________________________________________________________________");
  println("Prøver på skape forbindelse imellom arduinio og processing...");
  println("_____________________________________________________________________");

  while(true){ //loop som kjører helt til vi breaker
    //tester om kobling imellom arduino og processing er ok
    myPort.write('A');  //char samsvarer med tilsvarende case i .ino fil - vi skriver tegnet til serial og håper på at arduino tar den opp
    serielldata = lesSeriellData(100); //vi leser fra seriell data vi mottar fra arduino
    if (serielldata.equals("koblingok")){ //om arduino skrev koblingok til terminalen, mottok den 'A', kobling er derfor sikker!
      println("_______________");
      println("Kobling er ok! |");
      println("_______________|");
      serielldata = "";
      break;
    } else {
      tilkoblingsForsok++;
      println("Prøver å koble... forsok nr:  " + tilkoblingsForsok + "|");
      delay(100);
      if(tilkoblingsForsok > 10){
        println("Overstiget 10 forsøk på å koble til. Noe er galt, prøv på nytt"); //dette hender ofte fordi man ikke lar arduino fil laste opp helt før man kjører processing.
        exit();
        return;
      }
        
    }
  }
    
  
    delay(1000);
    quizzen = new Quiz(); //skaper nytt quiz objekt, og henter spørsmål fra testFil.csv
    quizzen.hentSporsmolfraTable();
    
    println("|                      |                                    |                           |");
    println("|                      |      spiller velkommen fil......   |                           |");
        spillLyd("velkommen.mp3");
    println("|                      |                                    |                           |");
    println("|                      |                                    |                           |");
    println("|                      |            SETUP FERDIG            |                           |");
    println("|_______________________________________________________________________________________|");
    println("\n\n\n\n"); 
    //dette ser kulere ut i serial monitor ^^, jeg lover
}

//________________________________________________________________________________________________________________________
//DRAW - KJØRES CONTINUERLIG
//________________________________________________________________________________________________________________________


void draw(){
  
  int sporsmolNr = quizzen.hentNesteSporsmol(); //henter neste spørsmål, dette henter et tilfeldig spørsmål, skriver ut spørsålet sin informasjon og spiller av lyd.
   
   //Henter input fra knapper
   String valgtAlternativ = ""; //knapp alternativ
    myPort.write('K'); //handshake protokoll med arduino
    while (valgtAlternativ ==""){
    // les seriell data
    serielldata = lesSeriellData(1500); 
      if (serielldata.equals("A")){
          valgtAlternativ = "A"; //setter variabel valgalternativ til det vi leser fra seriell data.
          break;
      }
      if (serielldata.equals("B")){
          valgtAlternativ = "B";
          break;
      }
      if (serielldata.equals("C")){
          valgtAlternativ = "C";
          break;
      }
      if (serielldata.equals("D")){
          valgtAlternativ = "D";
          break;
      } else {
        valgtAlternativ = ""; //om vi ikke får gyldig data, er valgtAlternativ tom og vi kjører på nytt.
      }
  }
  
   String riktigAlternativ = quizzen.vaaresporsmol[sporsmolNr].hentRiktigSvar(); //finner riktig alternativ fra table
  println("--------------------------------");
  println("REGISTRERT SVAR : |" + valgtAlternativ + "| RIKTIG SVAR:  |" +riktigAlternativ + "|"); //skriver ut vårt valgte alternativ

  println("--------------------------------");

  if (valgtAlternativ.equals(riktigAlternativ)){ //om disse samsvarer (bruker har rett):
      //spillLyd("poeng_opp.mp3");
    
      println("CASE P KJØRES: (endre poeng)");
      myPort.write('P'); //ny case som skal øke poeng og lys med 1.
          serielldata = lesSeriellData(100);
          while (poengOkt == false){
                  serielldata = lesSeriellData(100);
                  if (serielldata.equals("ookpoeng")){ //om vi mottar stringen ookpoeng fra arduino, er koblingen sikker, og et led lys skal lyse opp.
                    println("Seriell data lest inn: " + serielldata);
                    poengOkt = true;
                  } else if (serielldata == null || serielldata.equals("")){
                    break;
                  }
          }
          
          println("");
          serielldata = lesSeriellData(100);
          if (serielldata.equals("proverAaSkrivePoeng...")){
           
                serielldata = lesSeriellData(100);
                while (rawPoeng<8){
                  rawPoeng = Integer.parseInt(serielldata);
                  poeng = rawPoeng-1; //setter variabel poeng til det vi leser fra arduino
                  break;
                }
            }
          if (serielldata.equals("poengsettingsERROR")){
            println("feil med poengsetting!");
          }
  } 
  else { //hvis brukern ikke hadde rett:
    println("Feil svar, spiller lydfil...");
    switch(riktigAlternativ){ //bruk riktigalternativ som case til å spille lydfilen som samsvarer med det riktige alternativet.
        case "A":{
          spillLyd("feil_a.mp3"); 
          break;
        }
        case "B":{
          spillLyd("feil_b.mp3");
          break;
        }
        case "C":{
          spillLyd("feil_c.mp3");
          break;
        }
        case "D":{
          spillLyd("feil_d.mp3");
          break;
        }
      } 
  }
  println("poeng: " + poeng); //print poeng til serial
  
  //nå skal en runde har kjørt, vi øker derfor antferdigesporsmol med 1.
  quizzen.antFerdigeSporsmol = quizzen.antFerdigeSporsmol+1;
  
  if (quizzen.antFerdigeSporsmol >= 6 && poeng == 6){ //om vi har 6 poeng, og om vi har spilt mer enn 6 runder, er vi ferdige med runden (maxpoeng er 6 fordi led baren har 6 lys).
    println("--------------------------------SPILLET ER FULLFØRT, BRUKER VANT PÅ " + quizzen.antFerdigeSporsmol + 
      " RUNDER " + "--------------------------------");
     
    myPort.write('K'); //ny case der vi igjen kaller på sjekkKnapp på arduino.
    serielldata = "";
    serielldata = lesSeriellData(100);
    println("Trykk på hvilken som helst av knappene for å avslutte");
      if (serielldata.equals("A") || serielldata.equals("B") || serielldata.equals("C") || serielldata.equals("D")){
        println("Program avsluttet. ");
        exit();
        return;
          
      }
      myPort.write('L'); //ny case der vi skrur av alle lys.
         serielldata = lesSeriellData(100);
         println(serielldata);
         while (resett == false){
           serielldata = lesSeriellData(100);
           if (serielldata.equals("resettPoeng")){
             resett = true;
           }
         }
    exit();
    return;
   }  else { //om vi ikke har 6 poeng, og om vi ikke har spilt mer enn 6 runder, kan vi fortsette.
    println("--------------------------------RUNDE " + quizzen.antFerdigeSporsmol + " FULLFØRT--------------------------------");
    
  }
  
  //resetter variable til neste gang draw kjøres
  valgtAlternativ = "";
  serielldata = "";
  poengOkt = false;
  myPort.clear();
}
