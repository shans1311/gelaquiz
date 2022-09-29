
//variabler for knapper
int aKnapp =4; //blå
int bKnapp =5; //gul
int cKnapp = 6; //rød
int dKnapp = 7; //grønn

//variablerer som deklarer knappene sin tilstand
int a_state = 0; 
int b_state = 0;
int c_state = 0;
int d_state = 0;


//12,11,13

//Variabler for shift register (led bar)
const int latchPin = 12; //13,12,11
const int clockPin = 11;
const int dataPin = 13;
byte naaVerendeTilstand = 0; //tilstanden til led på starten (av)

//Diverse variabler
int poeng = 1;
int seriellData;
char valgtAlternativ;
String state;

// ---------------------------Egne Metoder -----------------------------------------

//Vi sjekker tilstanden til hver knapp, returner A, B, C ELLER D etter hvilken knapp som er trykket
void sjekkKnapp(){
  
        a_state = 0; 
        b_state = 0;
        c_state = 0;
        d_state = 0;

        //loopen kjører helt til vi breaker ut av den
        while(true){

          //leser digitalRead til knapper
          a_state = digitalRead(aKnapp);
          b_state = digitalRead(bKnapp);
          c_state = digitalRead(cKnapp);
          d_state = digitalRead(dKnapp);


          //om A er på, og de andre er av, er det valgte Alternativet A,
          if(a_state == 1 && b_state != 1 && c_state != 1 && d_state != 1){
            valgtAlternativ = 'A';
                        Serial.println(valgtAlternativ); 
            break;
          }
          //osv osv osv...
          else if(a_state != 1 && b_state == 1 && c_state != 1 && d_state != 1){
            valgtAlternativ = 'B';
                        Serial.println(valgtAlternativ);

            break;
          }
          else if(a_state != 1 && b_state != 1 && c_state == 1 && d_state != 1){
            valgtAlternativ = 'C';
                        Serial.println(valgtAlternativ);

            break;
          }
          else if(a_state != 1 && b_state != 1 && c_state != 1 && d_state == 1){
            valgtAlternativ = 'D';
                        Serial.println(valgtAlternativ);

            break;
          }
          
      }
}


//metode som lyser LED etter hvor mange poeng vi har
void skrivPoeng(){       
  Serial.println("proverAaSkrivePoeng...");

   //i shift register er LED på slot 2-7, dermed må poeng være lik verdi
   if (poeng != 1 && poeng <=7){
    int ledAaLyse = poeng; //leden vi vil lyse setter vi lik poeng
    Serial.println(ledAaLyse); //printer poeng for innlesing fra processing
    lysOpp(ledAaLyse, HIGH); //kaller på metode lysOpp som skal lyse opp LED 
   } else {
    Serial.println("poengsettingsERROR");
    }
 
}

//metode som bruker shift register til å lyse hver led
//parameter onsketLed er leden vi vil endre, tilstandHigh er tilstanden vi vil at de skal være etter
//metoden er kjørt (high)
void lysOpp(int onsketLed, int tilstandHigh) {

  
  
  digitalWrite(latchPin, LOW);// ha LED av før vi begynner å endre tilstand, imens vi sender bits 
  
  bitWrite(naaVerendeTilstand, onsketLed, tilstandHigh);   // naaverendetilstand er definert som 0, 
                                                          //endre denne tilstanden til high i onsketled

  shiftOut(dataPin, clockPin, MSBFIRST, naaVerendeTilstand); //shifter bits ut - altså at vi går til neste
                                                             //bit(input slot) i shift register
  
  digitalWrite(latchPin, HIGH);   //Led skal ha HIGH tilstand

  //Ved å sette denne til en, forblir led-en på når vi går til neste, 
  byte naaVerendeTilstand = 1;
}


// i motsetning med metoden skrivPoeng, ønsker vi her å skru av alle LED
void drepPoeng(){
  for (int i = 8; i>0; i--){
    skruAvLys(i); //kaller på  skruAvLys
    
    }
}
void skruAvLys(int onsketLed){ //har bare ønsketled som parameter, siden vi vet at vi vil gjøre alle LOW
  Serial.println("proverAaSkruAvPoeng..."); 
    int onsketTilstand = LOW; 
  
    digitalWrite(latchPin, HIGH); //når vi begynner metoden, antar vi at alle LED er high
    
    bitWrite(naaVerendeTilstand, onsketLed, onsketTilstand); //deres tilstand er high, og for hver led
                                                             //bytter vi det til onsket tilstand(LOW)

    shiftOut(dataPin, clockPin, MSBFIRST, onsketLed);        //shifter bits ut - altså at vi går til neste
                                                             //bit(input slot) i shift register
    digitalWrite(latchPin, LOW); //LED skal ha LOW tilstand.
  
}


// ---------------------------Setup og Loop -----------------------------------------


void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600); //essensiell for kommunikasjon med processig, forklares mer detaljert i rapport.
  //setter diverse input og output
  pinMode(aKnapp, INPUT);
  pinMode(bKnapp, INPUT);
  pinMode(cKnapp, INPUT);
  pinMode(dKnapp, INPUT);

  
  pinMode(latchPin, OUTPUT);
  pinMode(dataPin, OUTPUT);
  pinMode(clockPin, OUTPUT);

}

void loop() {


      seriellData = Serial.read(); 
      
      switch (seriellData) {

      case 'L': //case for å drepe lysene når maks poeng er oppnådd.
          Serial.println("resettPoeng");
          drepPoeng();
          break;
          

      case 'P':  //case for å øke poeng med en, samt lyse en ny LED i LED baren.
            Serial.println("ookpoeng"); 
            poeng++;
            skrivPoeng();

      case 'A': //case for å forsikre en sikker kobling imellom arduino og processing
        Serial.println("koblingok");
        break;

      case 'K': 
        sjekkKnapp(); //case for å lese inn input fra knapper
        Serial.println(String(valgtAlternativ));
        break;
        }    
}
