LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY UnitateCentrala IS
  PORT (
  	-- intrari ale UC
  	clock, start, usa, anulare: in std_logic;
  	temperatura: in std_logic_vector(1 downto 0);
  	viteza: in std_logic_vector(1 downto 0);
  	prespalare: in std_logic;
  	clatireSuplimentara: in std_logic;
  	mode: in std_logic_vector (2 downto 0);
	modSelectie: in std_logic;
	-- iesiri de la UC pentru UE
 	enPrespalare, enSpalare, enClatire, enClatireSuplimentara, enCentrifuga: out std_logic;
	-- iesiri de la UE pentru UC
 	gtPrespalare, gtSpalare, gtClatire, gtClatireSuplimentara, gtCentrifuga: in std_logic;

 	--iesire UC
 	gataSpalare: out std_logic
    );
END UnitateCentrala;

ARCHITECTURE turaDeSpalat OF UnitateCentrala IS

type State_T is (A_Idle, B_Prespalare, B_Spalare, C_Clatire, C_ClatireSuplimentara, D_Centrifuga, E_Gata);
signal State, nextState: State_T;
signal vitezaSelectata, rot: integer :=0;
signal spalare2, clatire2: integer :=0;
signal gata: integer :=0;

-- A -> idle, setari predefinite, setari manuale
-- B -> spalare/prespalare
-- C -> clatire
-- D -> centrifuga
-- E -> gata

-- moduri de spalare
-- 000 - spalare rapida
-- 001 - camasi
-- 010 - culori inchise
-- 011 - rufe murdare
-- 100 - antialergic

-- temperatura
-- 00 - 30
-- 01 - 40
-- 10 - 60
-- 11 - 90

-- modSelectie
-- 0, manual
-- 1, automat

BEGIN

-- dam update la stare
Update: process(clock, anulare)
		begin
			if(anulare = '1') then
				State <= A_Idle;
			elsif (rising_edge(clock)) then
				State <= NextState;
			end if;
		end process Update;

-- check organigrama
Transitions: process(start, anulare, usa, viteza, mode, modSelectie, prespalare, spalare2, clatireSuplimentara, clatire2, State, gtPrespalare, gtSpalare, gtClatire, gtClatireSuplimentara, gtCentrifuga)
			begin
				if(anulare = '1') then nextState <= A_Idle;
				else
				case State is
					when A_Idle =>
					if(start = '1' and usa= '1' and (prespalare = '1' or spalare2 = 1)) then nextState <= B_Prespalare;
					elsif (start ='1' and usa = '1' and (prespalare = '0' or spalare2 = 0)) then nextState <= B_Spalare;
					else nextState <= A_Idle;
					end if;

					when B_Prespalare =>
					if(gtPrespalare = '1') then nextState <= B_Spalare;
					else nextState <= B_Prespalare;
					end if;

					when B_Spalare =>
					if(gtSpalare = '1') then nextState <= C_Clatire;
					else nextState <= B_Spalare;
					end if;
					
					when C_Clatire =>
					if(gtClatire = '1' and (clatireSuplimentara = '1' or clatire2 = 1)) then nextState <= C_ClatireSuplimentara;
					elsif(gtClatire = '1' and (clatireSuplimentara = '0' or clatire2 = 0)) then nextState <= D_Centrifuga;
					else nextState<=C_Clatire;
					end if;

					when C_ClatireSuplimentara =>
					if(gtClatireSuplimentara = '1') then nextState <= D_Centrifuga;
					else nextState <= C_ClatireSuplimentara;
					end if;
					
					when D_Centrifuga =>
					if(gtCentrifuga = '1') then nextState <= E_Gata;
					else nextState <= D_Centrifuga;
					end if;

					when E_Gata =>
					nextState <= A_Idle;
				end case;
				end if;
			end process Transitions;

-- vezi relatii UC-UE
Outputs: process(start, anulare, viteza, usa, mode, modSelectie, prespalare, spalare2, clatireSuplimentara, clatire2, State, gtPrespalare, gtSpalare, gtClatire, gtClatireSuplimentara, gtCentrifuga)
		begin
			case State is
				when A_Idle =>
				vitezaSelectata <= 0; rot <= 0;
				enPrespalare<='0'; enSpalare<='0'; enClatire <='0'; enClatireSuplimentara<='0'; enCentrifuga<='0';
				if(gata = 0 or anulare = '1') then 
					gataSpalare <= '0'; gata <= 0;
					spalare2 <= 0; clatire2 <= 0;
				end if;
				
				if(modSelectie = '1') then
					if(to_integer(unsigned(mode)) = 0) then vitezaSelectata <= 1200;
					elsif(to_integer(unsigned(mode)) = 1) then vitezaSelectata <= 800;
					elsif(to_integer(unsigned(mode)) = 2) then vitezaSelectata <= 1000; clatire2 <= 1;
					elsif(to_integer(unsigned(mode)) = 3) then vitezaSelectata <= 1000; spalare2 <= 1;
					elsif(to_integer(unsigned(mode)) = 4) then vitezaSelectata <= 1200; clatire2 <= 1;
					end if;
				else
					if(viteza = 0) then vitezaSelectata <= 800;
					elsif(viteza = 1) then vitezaSelectata <= 1000;
					elsif(viteza = 2) then vitezaSelectata <= 1200;
					end if;
				end if;
	
				when B_Prespalare =>
				if(prespalare = '1' or spalare2 = 1) then
					enPrespalare <= '1'; rot <= 60;
				end if;

				when B_Spalare =>
				if(gata = 0) then enSpalare<='1'; rot <= 60; end if;
				
				when C_Clatire =>
				if(gata = 0) then enClatire <= '1'; rot <= 120; end if; -- enClatire

				when C_ClatireSuplimentara =>
				if(clatireSuplimentara = '1' or clatire2 = 1) then 
					if(gata = 0) then enClatireSuplimentara <= '1'; rot <= 120; end if; -- enClatireSuplimentara
				end if;
	
				when D_Centrifuga =>
				if(gata = 0) then enCentrifuga <= '1'; rot <= vitezaSelectata; end if;
			
				when E_Gata =>
				if(gata = 0) then gataSpalare <= '1'; gata <= 1; rot <= 0; end if;
			end case;
		end process Outputs;

END turaDeSpalat;
