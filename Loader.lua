-- Prime Void Hub | Universal Loader
local placeId=tonumber(game.PlaceId) or 0
local universeId=tonumber(game.GameId) or 0
local ports={
    {
        name='Storm Suite',
        version='v1.0.0',
        officialName='Ride Storm',
        placeIds={[12593620250]=true},
        universeIds={[4420562665]=true},
        url='https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua',
        markers={'SOURCE GITHUB v','local function setupInterfaceAndLoops()','Prime Void Hub - Storm Suite'},
    },
    {
        name='Grau SP',
        version='v0.4.11',
        officialName='Grau SP',
        placeIds={[101953291486308]=true},
        universeIds={[7938305201]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/grau-sp.lua',
        markers={'-- Prime Void Hub | GRAU SP | v0.4.11','env.PVH_GrauSP_Unload'},
    },
    {
        name='War Tycoon',
        version='v0.1.1',
        officialName='War Tycoon',
        placeIds={[4639625707]=true},
        universeIds={[1526814825]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/war-tycoon.lua',
        markers={'-- Prime Void Hub | War Tycoon | v0.1.1','PVH_WarTycoonUnload'},
    },
    {
        name='Huntress',
        officialName='HUNTRESS',
        version='v1.1.1',
        placeIds={[104259439179020]=true,[110394010715338]=true},
        universeIds={[10416475193]=true},
        url='https://prime-void-hub-huntress-gateway.vercel.app/huntress.lua',
        markers={'Prime Void Hub - Huntress','PVHuntressUnload','Library:CreateWindow'},
    },
    {
        name='Exu Security Lab',
        version='v1.1.2',
        officialName='Steal An Exu',
        placeIds={[103076400317371]=true},
        universeIds={},
        url='https://prime-void-hub-exu-gateway.vercel.app/exu-security-lab.lua',
        markers={'local rarityList=','Prime Void | Exu Security Lab'},
    },
    {
        name='Destruction Simulator',
        version='v0.2.4',
        officialName='Destruction Simulator',
        placeIds={[2248408710]=true},
        universeIds={},
        url='https://prime-void-hub-destruction-gateway.vercel.app/destruction-simulator.lua',
        markers={'-- Prime Void Hub | Destruction Simulator | v0.2.4 TEST','local Airflow={}','global.PVDestructionUnload'},
    },
    {
        name='Dont Splash Explorer',
        version='v0.1.2',
        officialName="Don't Splash",
        placeIds={[139386728420706]=true},
        universeIds={},
        url='https://prime-void-hub-splash-gateway.vercel.app/dont-splash.lua',
        markers={'-- Prime Void Hub - Dont Splash','PVDontSplashUnload','Library:CreateWindow'},
    },
    {
        name='Clover Legends',
        version='v0.1.11',
        officialName='Clover Legends: Devil Fusion',
        placeIds={[109813591245812]=true},
        universeIds={[10769707586]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/clover.lua',
        markers={'Prime Void Hub | Clover Legends','PVH_CloverUnload'},
    },
    {
        name='Roube um Espírito Santo',
        version='v0.1.9',
        officialName='Roube um Espírito Santo',
        placeIds={[86004028558873]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/spirit-sanctuary.lua',
        markers={'-- Prime Void Hub | Roube um Espírito Santo | v0.1.9','PVH_SpiritUnload'},
    },
    {
        name='Da Hood',
        version='v0.1.1',
        officialName='Da Hood',
        placeIds={[2788229376]=true,[7213786345]=true},
        universeIds={[1008451066]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/da-hood.lua',
        markers={'-- Prime Void Hub | Da Hood | v0.1.1','PV_DaHoodUnload'},
    },
    {
        name='RIVALS',
        version='v0.1.2',
        officialName='RIVALS',
        placeIds={[17625359962]=true},
        universeIds={[6035872082]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/rivals.lua',
        markers={'-- Prime Void Hub | RIVALS | v0.1.2'},
    },
    {
        name='Steal a Brainrot',
        version='v0.1.0',
        officialName='Steal a Brainrot',
        placeIds={[109983668079237]=true},
        universeIds={[7709344486]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/brainrot.lua',
        markers={'-- Obscura ['},
    },
    {
        name='RATO',
        version='v0.1.1',
        officialName='RATO',
        placeIds={[81688312343760]=true},
        universeIds={[10769420234]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/rato.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Anime RNG Defense',
        version='v0.1.0',
        officialName='Anime RNG Defense',
        placeIds={[104693964860826]=true},
        universeIds={[9940812243]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/anime-rng-defense.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Chicken Farm',
        version='v0.1.0',
        officialName='Chicken Farm',
        placeIds={[137233438285284]=true},
        universeIds={[10209534490]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/chicken-farm.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Spin a Car',
        version='v0.1.0',
        officialName='Spin a Car',
        placeIds={[136758055891411]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/spin-a-car.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Merge a Nuke!',
        version='v0.1.0',
        officialName='Merge a Nuke!',
        placeIds={[128784467030899]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/merge-a-nuke.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Roll for Anime!',
        version='v0.1.0',
        officialName='Roll for Anime!',
        placeIds={[107706720875645]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/roll-for-anime.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Build a Keyboard',
        version='v0.1.0',
        officialName='Build a Keyboard',
        placeIds={[91679585668032]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/build-a-keyboard.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='2omething evil will happen',
        version='v0.1.0',
        officialName='2omething evil will happen',
        placeIds={[16991287194]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/2omething-evil-will-happen.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Make a Drill Farm',
        version='v0.1.0',
        officialName='Make a Drill Farm',
        placeIds={[79315121100812]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/make-a-drill-farm.lua',
        markers={'-- Obscura VM ['},
    },    {
        name='+1 Clone Evolution',
        officialName='+1 Clone Evolution',
        version='v0.2.0',
        placeIds={[120297898552393]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-clone-evolution.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Dino Evolution',
        officialName='+1 Dino Evolution',
        version='v0.2.0',
        placeIds={[103138601755519]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-dino-evolution.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 DMG FPS',
        officialName='+1 DMG FPS',
        version='v0.2.0',
        placeIds={[100753254401525]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-dmg-fps.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Fart to Break Doors',
        officialName='+1 Fart to Break Doors',
        version='v0.2.0',
        placeIds={[120285538222067]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-fart-to-break-doors.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Mog Evolution',
        officialName='+1 Mog Evolution',
        version='v0.2.0',
        placeIds={[92648272637932]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-mog-evolution.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Slash Per Click!',
        officialName='+1 Slash Per Click!',
        version='v0.2.0',
        placeIds={[101558013317432]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-slash-per-click.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Stone Skipping',
        officialName='+1 Stone Skipping',
        version='v0.2.0',
        placeIds={[111543903102439]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-stone-skipping.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Strength for Eggs',
        officialName='+1 Strength for Eggs',
        version='v0.2.0',
        placeIds={[98610101874791]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-strength-for-eggs.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Sword vs Anime',
        officialName='+1 Sword vs Anime',
        version='v0.2.0',
        placeIds={[72600023868608]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-sword-vs-anime.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 TNT Mining',
        officialName='+1 TNT Mining',
        version='v0.2.0',
        placeIds={[101304595834078]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-tnt-mining.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Chop Tree and Ride Pet',
        officialName='+1 Chop Tree and Ride Pet',
        version='v0.2.0',
        placeIds={[78793646042773]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-cut-and-ride-pet.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Tongue Escape',
        officialName='+1 Tongue Escape',
        version='v0.2.0',
        placeIds={[122245938604556]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-tongue-escape.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Anomaly Garden',
        officialName='Anomaly Garden',
        version='v0.2.0',
        placeIds={[114302935980927]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/anomaly-garden.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Become a Billionaire',
        officialName='Become a Billionaire',
        version='v0.2.0',
        placeIds={[90704250333473]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/become-a-billionaire.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Blow up Lucky Blocks For Cars',
        officialName='Blow up Lucky Blocks For Cars',
        version='v0.2.0',
        placeIds={[77084002576266]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/blow-up-lucky-blocks-for-cars.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Break an Egg!',
        officialName='Break an Egg!',
        version='v0.2.0',
        placeIds={[128683790553857]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/break-an-egg.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Build Golems and Fight',
        officialName='Build Golems and Fight',
        version='v0.2.0',
        placeIds={[101145494627874]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/build-golems-and-fight.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Collect 1 Million Items',
        officialName='Collect 1 Million Items',
        version='v0.2.0',
        placeIds={[133363783004873]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/collect-1-million-items.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Drive-Thru Empire',
        officialName='Drive-Thru Empire',
        version='v0.2.0',
        placeIds={[88271351034688]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/drive-thru-empire.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Fruit Zombie Survival',
        officialName='Fruit Zombie Survival',
        version='v0.2.0',
        placeIds={[75290583112878]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/fruit-zombie-survival.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Jump To Steal An Egg',
        officialName='Jump To Steal An Egg',
        version='v0.2.0',
        placeIds={[106383201135975]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/jump-to-steal-an-egg.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Lift a Cube',
        officialName='Lift a Cube',
        version='v0.2.0',
        placeIds={[109530157755211]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/lift-a-cube.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Make Hotsauce',
        officialName='Make Hotsauce',
        version='v0.2.0',
        placeIds={[122391683154858]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/make-hotsauce.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Merge a Dino',
        officialName='Merge a Dino',
        version='v0.2.0',
        placeIds={[84546345526935]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/merge-a-dino.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Motorcycle for Animals',
        officialName='Motorcycle for Animals',
        version='v0.2.0',
        placeIds={[84403204002907]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/motorcycle-for-animals.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='My Anime Mine',
        officialName='My Anime Mine',
        version='v0.2.0',
        placeIds={[79389059854988]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/my-anime-mine.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='My Dino Park!',
        officialName='My Dino Park!',
        version='v0.2.0',
        placeIds={[80701570784699]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/my-dino-park.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='My Lucky Train',
        officialName='My Lucky Train',
        version='v0.2.0',
        placeIds={[122245209010944]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/my-lucky-train.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Open Sea For Animals!',
        officialName='Open Sea For Animals!',
        version='v0.2.0',
        placeIds={[88047783411976]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/open-sea-for-animals.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Pets Universe!',
        officialName='Pets Universe!',
        version='v0.2.0',
        placeIds={[74629631798007]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/pets-universe.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Race Horses',
        officialName='Race Horses',
        version='v0.2.0',
        placeIds={[79475945127283]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/race-horses.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Roller for Animals!',
        officialName='Roller for Animals!',
        version='v0.2.0',
        placeIds={[88910662712492]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/roller-for-animals.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Sail For Eggs',
        officialName='Sail For Eggs',
        version='v0.2.0',
        placeIds={[121443295737695]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/sail-for-eggs.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Snowcone Stand',
        officialName='Snowcone Stand',
        version='v0.2.0',
        placeIds={[76113971506717]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/snowcone-stand.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Steal a Giant Egg',
        officialName='Steal a Giant Egg',
        version='v0.2.0',
        placeIds={[136448020793455]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/steal-a-giant-egg.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Backrooms Simulator',
        officialName='Backrooms Simulator',
        version='v0.2.0',
        placeIds={[126061186342944]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/backrooms-simulator.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Beat the Anime Boss!',
        officialName='Beat the Anime Boss!',
        version='v0.2.0',
        placeIds={[129216769649527]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/beat-the-anime-boss.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Brainrot Card Battles',
        officialName='Brainrot Card Battles',
        version='v0.2.0',
        placeIds={[124124395449044]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/brainrot-card-battles.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Choose the Stronger Anime!',
        officialName='Choose the Stronger Anime!',
        version='v0.2.0',
        placeIds={[111801263516291]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/choose-the-stronger-anime.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Collect Cars and Race',
        officialName='Collect Cars and Race',
        version='v0.2.0',
        placeIds={[120579221585812]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/collect-cars-and-race.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Fishing Chef',
        officialName='Fishing Chef',
        version='v0.2.0',
        placeIds={[88599461076137]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/fishing-chef.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Fishing Wars',
        officialName='Fishing Wars',
        version='v0.2.0',
        placeIds={[106605020123719]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/fishing-wars.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Hatch And Fry!',
        officialName='Hatch And Fry!',
        version='v0.2.0',
        placeIds={[124472567087489]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/hatch-and-fry.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Magnet Fishing',
        officialName='Magnet Fishing',
        version='v0.2.0',
        placeIds={[83717725495693]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/magnet-fishing.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Merge a Squishy',
        officialName='Merge a Squishy',
        version='v0.2.0',
        placeIds={[117740102453431]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/merge-a-squishy.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Project Aura RNG',
        officialName='Project Aura RNG',
        version='v0.2.0',
        placeIds={[129619503633658]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/project-aura-rng.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Rescue Animals!',
        officialName='Rescue Animals!',
        version='v0.2.0',
        placeIds={[108454764166583]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/rescue-animals.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Roll a Sorcerer',
        officialName='Roll a Sorcerer',
        version='v0.2.0',
        placeIds={[77876346348868]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/roll-a-sorcerer.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='RUNAWAYS',
        officialName='RUNAWAYS',
        version='v0.2.0',
        placeIds={[118418618261207]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/runaways.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Steal A Lucky Egg',
        officialName='Steal A Lucky Egg',
        version='v0.2.0',
        placeIds={[123698673940079]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/steal-a-lucky-egg.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Long Arm Toy Escape!',
        officialName='+1 Long Arm Toy Escape!',
        version='v0.2.0',
        placeIds={[74341114342499]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-long-arm-toy-escape.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Power Jujutsu Kaisen Evolution',
        officialName='+1 Power Jujutsu Kaisen Evolution',
        version='v0.2.0',
        placeIds={[73768088906246]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-power-jujutsu-kaisen-evolution.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Speedster Escape',
        officialName='+1 Speedster Escape',
        version='v0.2.0',
        placeIds={[85065221510105]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-speedster-escape.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Spider Evolution',
        officialName='+1 Spider Evolution',
        version='v0.2.0',
        placeIds={[135830878717711]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-spider-evolution.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='+1 Sword Fighting Escape',
        officialName='+1 Sword Fighting Escape',
        version='v0.2.0',
        placeIds={[71132391335247]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/1-sword-fighting-escape.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Basketball Dynasty',
        officialName='Basketball Dynasty',
        version='v0.2.0',
        placeIds={[91696807303847]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/basketball-dynasty.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Break For Anime!',
        officialName='Break For Anime!',
        version='v0.2.0',
        placeIds={[83337738588990]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/break-for-anime.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Farmers Market!',
        officialName='Farmers Market!',
        version='v0.2.0',
        placeIds={[108479378357844]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/farmers-market.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Jump To Steal SCP Monsters!',
        officialName='Jump To Steal SCP Monsters!',
        version='v0.2.0',
        placeIds={[123724279728430]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/jump-to-steal-scp-monsters.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Pop & Collect',
        officialName='Pop & Collect',
        version='v0.2.0',
        placeIds={[72390882197205]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/pop-bubbles.lua',
        markers={'-- Obscura VM ['},
    },
    {
        name='Roll Anime & Fight',
        officialName='Roll Anime & Fight',
        version='v0.2.0',
        placeIds={[115690665465501]=true},
        universeIds={},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/roll-anime-fight.lua',
        markers={'-- Obscura VM ['},
    },

}
local selected
for _,port in ipairs(ports) do
    if port.placeIds[placeId] or port.universeIds[universeId] then
        selected=port
        break
    end
end
-- Carry a supported port across sibling places of the same experience.
-- Queue handoff state is embedded in the teleport payload, so it works even
-- when the executor's file workspace is scoped per place or experience.
local transportEnv=(type(getgenv)=='function' and getgenv()) or _G
local supportedGameNames={}
local officialGameNamesByPlaceId={}
for _,item in ipairs(ports)do
    local officialName=item.officialName or item.name
    supportedGameNames[#supportedGameNames+1]=officialName
    for gamePlaceId in pairs(item.placeIds or {}) do
        officialGameNamesByPlaceId[tonumber(gamePlaceId)]=officialName
    end
end
transportEnv.PVH_SupportedGames=supportedGameNames
transportEnv.PVH_OfficialGameNamesByPlaceId=officialGameNamesByPlaceId

-- Executor name is client-reported; do not collect HWID, tokens or machine IDs.
local function pvhExecutorIdentity()
    local scopes={}
    local function add(label,value)
        if type(value)~='table' then return end
        for _,item in ipairs(scopes) do if item.obj==value then return end end
        scopes[#scopes+1]={label=label,obj=value}
    end
    add('getgenv',transportEnv)
    if type(getfenv)=='function' then
        local ok,value=pcall(getfenv,0)
        if ok then add('getfenv',value) end
    end
    add('_G',_G)
    add('shared',shared)
    add('direct',{identifyexecutor=identifyexecutor,getexecutorname=getexecutorname,getexecutorinfo=getexecutorinfo})
    local seen,attempts={},{}
    local function validName(value)
        if type(value)=='table' then
            value=value.name or value.Name or value.executorName or value.ExecutorName or value[1]
        end
        if type(value)~='string' then return nil end
        value=value:match('^%s*(.-)%s*$') or ''
        if #value<2 then return nil end
        local low=value:lower()
        for _,invalid in ipairs({'unknown','nil','none','undefined','n/a','não identificado',
            'nao identificado','not identified','unidentified'}) do
            if low==invalid then return nil end
        end
        return value:sub(1,60)
    end
    local name,method
    for _,item in ipairs(scopes) do
        for _,key in ipairs({'identifyexecutor','getexecutorname','getexecutorinfo'}) do
            local ok,fn=pcall(function()return item.obj[key]end)
            if ok and type(fn)=='function' and not seen[fn] then
                seen[fn]=true
                local success,result=pcall(fn)
                local reported=success and validName(result) or nil
                attempts[#attempts+1]=item.label..'.'..key..'='
                    ..(reported and 'valid' or (success and 'empty' or 'error'))
                if reported then
                    name=reported
                    method='api:'..item.label..'.'..key
                    break
                end
            end
        end
        if name then break end
    end
    if not name then
        -- Brand-signature inference is explicitly labeled; it is not proof.
        local brandKeys={Wave='Wave',Solara='Solara',Delta='Delta',Fluxus='Fluxus',
            Krnl='KRNL',KRNL_LOADED='KRNL',Potassium='Potassium',
            Velocity='Velocity',Xeno='Xeno',Trigon='Trigon',Codex='Codex'}
        local found,count={},0
        local sole=nil
        for _,item in ipairs(scopes) do
            for key,brand in pairs(brandKeys) do
                local ok,value=pcall(function()return item.obj[key]end)
                if ok and value~=nil and value~=false and not found[brand] then
                    found[brand]=true
                    sole=brand
                    count+=1
                end
            end
        end
        if count==1 then
            name=sole..' (provável)'
            method='signature:inferred'
        end
    end
    name=name or 'Não identificado'
    method=method or 'api_missing_or_invalid'
    local diagnostic='Executor: '..name..'\nMethod: '..method
        ..'\nAPI attempts: '..tostring(#attempts)..'\n'
        ..table.concat(attempts,'\n')..'\n'
    transportEnv.PVH_ExecutorDiagnostic=diagnostic
    warn('[PVH Analytics] Executor: '..name..' | '..method
        ..' | attempted APIs: '..tostring(#attempts))
    if type(writefile)=='function' then
        pcall(writefile,'PVH_ExecutorDiagnostics.txt',diagnostic)
    end
    return name,method
end

local carry=transportEnv.PVH_AutoexecCarry
transportEnv.PVH_AutoexecCarry=nil
local carriedPort
if type(carry)=='table' and carry.autoexec==true then
    for _,port in ipairs(ports) do
        if port.name==carry.port then carriedPort=port break end
    end
end
if not selected and carriedPort and universeId~=0
    and tonumber(carry.originUniverse)==universeId then
    selected=carriedPort
end
if type(carry)=="table" and carry.autoexec==true then
    warn("[PVH Autoexec] ROUTING | place="..tostring(placeId)
        .." | universe="..tostring(universeId)
        .." | carried="..tostring(carry.port)
        .." | selected="..tostring(selected and selected.name or "unsupported"))
end
-- Friendly unsupported-game dialog. Copying uses the executor clipboard when available.
-- If clipboard support is missing, show a selectable address instead of claiming success.
local function showUnsupportedGame(isPaused)
    -- Use the same pinned Obsidian library as the supported Prime Void Hub ports.
    -- This UI does not execute a game port or change the supported-game roster.
    local gameLink='https://www.roblox.com/games/'..tostring(placeId)
    local discordLink='https://discord.gg/PD3PeyG8aq'
    local env=type(getgenv)=='function' and getgenv() or _G
    if type(env.PVH_UnsupportedUIUnload)=='function' then
        pcall(env.PVH_UnsupportedUIUnload)
    end

    local Library
    local ok,reason=pcall(function()
        local loaded,lib=pcall(function()
            return loadstring(game:HttpGet(
                'https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua'
            ))()
        end)
        if not loaded or type(lib)~='table' then
            error('Biblioteca Obsidian indisponível: '..tostring(lib))
        end
        Library=lib
        Library.ShowCustomCursor=false

        local Window=Library:CreateWindow({
            Title='Prime Void Hub',
            Footer=isPaused and 'Universal Loader | Port em manutenção' or 'Universal Loader | Aviso v1.0.1 (31/10)',
            Center=true,
            AutoShow=true,
            Resizable=true,
            Size=UDim2.fromOffset(600,390),
            ShowCustomCursor=false,
            -- Never use Unknown: mouse/touch clicks also report that KeyCode.
            ToggleKeybind=Enum.KeyCode.RightControl,
            NotifySide='Right',
            MinSidebarWidth=140,
            EnableCompacting=true,
            SidebarCompactWidth=48,
            Animations={
                ToggleWindow=false,TabSwitch=false,Groupbox=false,
                Dropdown=false,KeyPicker=false,
            },
        })
        -- This informational window has no minimize keybind.
        -- nil never matches an Input.KeyCode; only 'Fechar' dismisses it.
        Library.ToggleKeybind=nil
        local tab=Window:AddTab('Suporte','life-buoy')
        -- Visible UI build marker: verify what code actually reached the executor.
        local uiBuild=isPaused and 'Aviso de manutenção | 07/11/2026' or 'Aviso v1.0.1 | 31/10/2026'

        local details=tab:AddGroupbox({
            Side='Left',Name='Jogo não suportado',IconName='circle-alert',
            DisableCollapsing=true,
        })
        details:AddLabel(isPaused and 'Roube um Exu está temporariamente sem suporte no Prime Void Hub.' or 'Este jogo ainda não é suportado pelo Prime Void Hub.',true)
        details:AddLabel(uiBuild,false)
        details:AddLabel(isPaused and 'Script pausado para manutenção. A versão atual encontra-se detectada. Aguarde a atualização antes de utilizar.' or 'Quer sugerir um port? Envie o link do jogo em nosso Discord.',true)
        details:AddDivider()
        details:AddLabel('PlaceId: '..tostring(placeId),true)

        local links=tab:AddGroupbox({
            Side='Right',Name='Links e comunidade',IconName='link',
            DisableCollapsing=true,
        })
        -- Obsidian Input uses TextScaled=true, shrinking long URLs to tiny text.
        -- Show the full URL in a readable, wrapping label too.
        links:AddLabel({Text=gameLink,DoesWrap=true,Size=16})
        local linkInput=links:AddInput('PVH_UnsupportedLink',{
            Text='Link para copiar',
            Default=gameLink,
            ClearTextOnFocus=false,
            ClearTextOnBlur=false,
            AllowEmpty=false,
            Finished=true,
        })
        -- Keep the editable field legible even for long PlaceIds.
        -- The TextBox can scroll horizontally when selected.
        local linkBox=linkInput.Holder and linkInput.Holder:FindFirstChildOfClass('TextBox')
        if linkBox then
            linkBox.TextScaled=false
            linkBox.TextSize=14
            linkBox.TextXAlignment=Enum.TextXAlignment.Left
        end
        local status=links:AddLabel('Use os botões abaixo ou copie o campo acima.',true)
        local function copyLink(url,successMessage)
            linkInput:SetValue(url)
            local clipboard=type(setclipboard)=='function' and setclipboard
                or (type(toclipboard)=='function' and toclipboard)
            if clipboard and pcall(clipboard,url) then
                status:SetText(successMessage)
            else
                status:SetText('Cópia indisponível: selecione o campo acima para copiar.')
            end
        end
        links:AddButton({
            Text='Copiar link do jogo',IconName='copy',
            Func=function()
                copyLink(gameLink,'Link do jogo copiado!')
            end,
        })
        links:AddButton({
            Text='Copiar Discord',IconName='message-circle',
            Func=function()
                copyLink(discordLink,'Convite do Discord copiado!')
            end,
        })
        links:AddDivider()
        links:AddButton({
            Text='Fechar',IconName='x',
            Func=function() Library:Unload() end,
        })

        local function unload()
            if Library and not Library.Unloaded then
                Library:Unload()
            end
        end
        env.PVH_UnsupportedUIUnload=unload
        Library:OnUnload(function()
            if env.PVH_UnsupportedUIUnload==unload then
                env.PVH_UnsupportedUIUnload=nil
            end
        end)
    end)
    if not ok then
        if Library and not Library.Unloaded then
            pcall(function() Library:Unload() end)
        end
        warn('[Prime Void Hub] '..(isPaused and 'Roube um Exu pausado para manutenção (versão detectada)' or 'Jogo não suportado')..' | PlaceId='..tostring(placeId)
            ..' | UI Obsidian falhou: '..tostring(reason)
            ..' | Discord: '..discordLink)
        pcall(function()
            game:GetService('StarterGui'):SetCore('SendNotification',{
                Title='Prime Void Hub',
                Text=isPaused and 'Roube um Exu pausado para manutenção: versão detectada.' or 'Jogo não suportado. Sugira este jogo no Discord!',
                Duration=8,
            })
        end)
    end
end
-- Exu is available again; Auto Farm is locked after the UI loads.
-- Unsupported games are also meaningful analytics events. Do not require
-- an active gameplay port or execute any unsupported port code.
local function sendUnsupportedRunLog()
    local env=transportEnv
    local world=tostring(game.PlaceId)..":"..tostring(game.JobId)
    if env.PVH_UnsupportedLogGame==game and env.PVH_UnsupportedLogWorld==world then return end
    env.PVH_UnsupportedLogGame=game
    env.PVH_UnsupportedLogWorld=world
    local ok,accepted=pcall(function()
        local req=env.request or env.http_request or request or http_request
            or (type(syn)=="table" and syn.request)
        if type(req)~="function" then return false end
        local player=game:GetService("Players").LocalPlayer
        if not player then return false end
        local gameName=""
        local infoOK,info=pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(
                game.PlaceId,Enum.InfoType.Asset)
        end)
        if infoOK and type(info)=="table" and type(info.Name)=="string" then
            gameName=info.Name
        end
        if gameName=="" then
            gameName=tostring(game.Name or ("PlaceId "..tostring(game.PlaceId)))
        end
        local executor,executorMethod=pvhExecutorIdentity()
        local payload=game:GetService("HttpService"):JSONEncode({
            username=player.Name,userId=tostring(player.UserId),
            placeId=tostring(game.PlaceId),gameName=gameName:sub(1,80),
            executor=executor,executorMethod=executorMethod,version="Universal",
            supported=false,supportStatus="unsupported",
        })
        local response=req({
            Url="https://prime-void-hub-exu-gateway.vercel.app/api/telemetry",
            Method="POST",Headers={["Content-Type"]="application/json"},
            Body=payload,
        })
        if type(response)=="table" then
            local status=tonumber(response.StatusCode or response.Status)
            if status and (status<200 or status>=300) then return false end
        end
        return true
    end)
    if not ok or accepted~=true then
        env.PVH_UnsupportedLogGame=nil
        env.PVH_UnsupportedLogWorld=nil
        warn("[PVH Analytics] Unsupported experience delivery not confirmed")
    end
end
if not selected then
    task.spawn(sendUnsupportedRunLog)
    -- An unsupported lobby is not the end of an autoexec chain. Stay armed
    -- for the next teleport without executing a wrong game's port.
    if carriedPort then
        local okBridge,errBridge=pcall(function()
            local moduleURL='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Persistence.lua'
            local factory,loadErr=loadstring(game:HttpGet(moduleURL..'?pvht='..tostring(os.time())))
            if not factory then error(loadErr) end
            local constructor=factory()
            if type(constructor)~='function' then error('Persistence constructor unavailable') end
            local old=transportEnv.PVH_Persistence
            if type(old)=='table' and type(old.Stop)=='function' then pcall(function()old:Stop()end) end
            local bridge=constructor({
                port=carriedPort.name,originUniverse=tonumber(carry.originUniverse),
                carryAutoexec=true,
                loaderUrl='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua',
            })
            transportEnv.PVH_Persistence=bridge
            bridge:Bridge()
        end)
        if not okBridge then warn('[PVH Autoexec] Bridge unavailable: '..tostring(errBridge)) end
    end
    showUnsupportedGame()
    return
end
local genv=type(getgenv)=='function' and getgenv() or _G
-- Clear an existing test overlay or previous universal loader overlay before rerunning.
local oldUXCleanup = genv.PVH_UX_UniversalCleanup or genv.PVH_UX_TestCleanup
if type(oldUXCleanup) == 'function' then
    pcall(oldUXCleanup)
end
genv.PVH_UX_TestCleanup = nil

-- Avoid duplicate launches only inside the SAME Roblox world.
-- Earlier guard used os.clock() alone; after a rejoin that clock may reset,
-- making a *negative* elapsed time incorrectly look like a duplicate.
local currentWorld=tostring(game.PlaceId)..':'..tostring(game.JobId)
-- Keep one successful telemetry delivery per port and server instance.
local analyticsRunKey=currentWorld..':'..selected.name
local previousWorld=genv.PVH_UniversalBootWorld
local previousLog=genv.PVH_UniversalAnalyticsSentKey==analyticsRunKey
genv.PVH_UniversalLoggerStatus={
    port=selected.name,
    gameName=selected.officialName,
    placeId=tostring(placeId),
    universeId=tostring(universeId),
    version=selected.version,
    state=previousLog and 'already_sent' or 'queued',
    runKey=analyticsRunKey,
}
if previousWorld~=currentWorld then genv.PV_Hub_AnalyticsSent=nil end
local lastBoot=genv.PVH_UniversalStartedAt
local elapsed=type(lastBoot)=='number' and (os.clock()-lastBoot) or nil
if previousWorld==currentWorld and genv.PVH_UniversalBootGame==game
    and type(elapsed)=='number' and elapsed>=0 and elapsed<2.5
    and genv.PV_Hub_ActivePort==selected.name then
    -- Multiple queued callbacks can fire during a single transition.
    -- The guard still rejects them, but print only once per world/port
    -- to avoid flooding testers' consoles.
    if genv.PVH_UniversalDuplicateWarnKey~=analyticsRunKey then
        genv.PVH_UniversalDuplicateWarnKey=analyticsRunKey
        warn('[PVH Autoexec v3] Duplicate loader invocation ignored in same server')
    end
    return
end
genv.PVH_UniversalBootWorld=currentWorld
genv.PVH_UniversalBootGame=game
genv.PVH_UniversalStartedAt=os.clock()
genv.PV_Hub_ActivePort=selected.name
-- Crash-safe boot trace: write before downloading or executing the RIVALS module.
if selected.name=='RIVALS' and type(writefile)=='function' then
    pcall(function()
        if type(makefolder)~='function' then return end
        for _,folder in ipairs({
            'primevoid_hub','primevoid_hub/RIVALS','primevoid_hub/RIVALS/Logs'
        }) do
            if type(isfolder)~='function' or not isfolder(folder) then
                makefolder(folder)
            end
        end
        writefile('primevoid_hub/RIVALS/Logs/PVH_Rivals_BootTrace.txt',
            '[PVH RIVALS] loader_selected | place='..tostring(placeId)
            ..' | version='..tostring(selected.version)..'\n')
    end)
end

local function sendUniversalRunLog()
    if previousLog or genv.PVH_UniversalAnalyticsSentKey==analyticsRunKey
        or genv.PV_Hub_AnalyticsSent==true
        or genv.PVH_UniversalAnalyticsPendingKey==analyticsRunKey then return end
    genv.PVH_UniversalAnalyticsPendingKey=analyticsRunKey
    local loggerStatus=genv.PVH_UniversalLoggerStatus
    if type(loggerStatus)=='table' and loggerStatus.runKey==analyticsRunKey then
        loggerStatus.state='sending'
    end
    local delivered,payload=pcall(function()
        local req=genv.request or genv.http_request
        local requestFn=type(req)=='function' and req
            or type(request)=='function' and request
            or type(http_request)=='function' and http_request
            or (type(syn)=='table' and type(syn.request)=='function' and syn.request)
        if type(requestFn)~='function' then return false end
        local player=game:GetService('Players').LocalPlayer
        if not player then return false end
        local executor,executorMethod=pvhExecutorIdentity()
        local json=game:GetService('HttpService'):JSONEncode({
            executor=executor,executorMethod=executorMethod,
            username=player.Name,
            userId=tostring(player.UserId),
            placeId=tostring(game.PlaceId),
            gameName=selected.officialName,
            supported=true,
            version=selected.version,
        })
        local response=requestFn({
            Url=selected.name=='Grau SP'
                and 'https://prime-void-hub-exu-gateway.vercel.app/api/telemetry-grau'
                or selected.name=='War Tycoon'
                and 'https://prime-void-hub-exu-gateway.vercel.app/api/telemetry-war'
                or 'https://prime-void-hub-exu-gateway.vercel.app/api/telemetry',
            Method='POST',
            Headers={['Content-Type']='application/json'},
            Body=json,
        })
        if type(response)~='table' then return false end
        local status=tonumber(response.StatusCode or response.Status)
        return status~=nil and status>=200 and status<300
    end)
    if genv.PVH_UniversalAnalyticsPendingKey==analyticsRunKey then
        genv.PVH_UniversalAnalyticsPendingKey=nil
    end
    local logged=delivered and payload==true
    if type(loggerStatus)=='table' and loggerStatus.runKey==analyticsRunKey then
        loggerStatus.state=logged and 'http_accepted' or 'unconfirmed'
    end
    if logged then
        genv.PV_Hub_AnalyticsSent=true
        genv.PVH_UniversalAnalyticsSentKey=analyticsRunKey
    else
        genv.PV_Hub_AnalyticsSent=nil
        warn('[PVH Analytics] HTTP delivery not confirmed for '..selected.name)
    end
end
-- Register the selected-port launch attempt before downloading or executing
-- the gameplay module. This also records ports that fail to compile or boot;
-- it does NOT claim that any in-game function succeeded.
task.spawn(sendUniversalRunLog)

-- This production loader executes validated PRE-PATCHED Obscura builds.
-- Runtime source transforms from the normal loader must never modify these VM sources.
local obfuscatedNames={
    ['Storm Suite']='storm.lua',
    ['Huntress']='huntress.lua',
    ['Exu Security Lab']='exu.lua',
    ['Destruction Simulator']='destruction.lua',
    ['Dont Splash Explorer']='splash.lua',
    ['Steal a Brainrot']='brainrot.lua',
    ['RIVALS']='rivals.lua',
    ['RATO']='rato.lua',
    ['Anime RNG Defense']='anime-rng-defense.lua',
    ['Chicken Farm']='chicken-farm.lua',
    ['Spin a Car']='spin-a-car.lua',
    ['Merge a Nuke!']='merge-a-nuke.lua',
    ['Roll for Anime!']='roll-for-anime.lua',
    ['Build a Keyboard']='build-a-keyboard.lua',
    ['2omething evil will happen']='2omething-evil-will-happen.lua',
    ['Make a Drill Farm']='make-a-drill-farm.lua',    ['+1 Clone Evolution']='1-clone-evolution.lua',
    ['+1 Dino Evolution']='1-dino-evolution.lua',
    ['+1 DMG FPS']='1-dmg-fps.lua',
    ['+1 Fart to Break Doors']='1-fart-to-break-doors.lua',
    ['+1 Mog Evolution']='1-mog-evolution.lua',
    ['+1 Slash Per Click!']='1-slash-per-click.lua',
    ['+1 Stone Skipping']='1-stone-skipping.lua',
    ['+1 Strength for Eggs']='1-strength-for-eggs.lua',
    ['+1 Sword vs Anime']='1-sword-vs-anime.lua',
    ['+1 TNT Mining']='1-tnt-mining.lua',
    ['+1 Chop Tree and Ride Pet']='1-cut-and-ride-pet.lua',
    ['+1 Tongue Escape']='1-tongue-escape.lua',
    ['Anomaly Garden']='anomaly-garden.lua',
    ['Become a Billionaire']='become-a-billionaire.lua',
    ['Blow up Lucky Blocks For Cars']='blow-up-lucky-blocks-for-cars.lua',
    ['Break an Egg!']='break-an-egg.lua',
    ['Build Golems and Fight']='build-golems-and-fight.lua',
    ['Collect 1 Million Items']='collect-1-million-items.lua',
    ['Drive-Thru Empire']='drive-thru-empire.lua',
    ['Fruit Zombie Survival']='fruit-zombie-survival.lua',
    ['Jump To Steal An Egg']='jump-to-steal-an-egg.lua',
    ['Lift a Cube']='lift-a-cube.lua',
    ['Make Hotsauce']='make-hotsauce.lua',
    ['Merge a Dino']='merge-a-dino.lua',
    ['Motorcycle for Animals']='motorcycle-for-animals.lua',
    ['My Anime Mine']='my-anime-mine.lua',
    ['My Dino Park!']='my-dino-park.lua',
    ['My Lucky Train']='my-lucky-train.lua',
    ['Open Sea For Animals!']='open-sea-for-animals.lua',
    ['Pets Universe!']='pets-universe.lua',
    ['Race Horses']='race-horses.lua',
    ['Roller for Animals!']='roller-for-animals.lua',
    ['Sail For Eggs']='sail-for-eggs.lua',
    ['Snowcone Stand']='snowcone-stand.lua',
    ['Steal a Giant Egg']='steal-a-giant-egg.lua',
    ['Backrooms Simulator']='backrooms-simulator.lua',
    ['Beat the Anime Boss!']='beat-the-anime-boss.lua',
    ['Brainrot Card Battles']='brainrot-card-battles.lua',
    ['Choose the Stronger Anime!']='choose-the-stronger-anime.lua',
    ['Collect Cars and Race']='collect-cars-and-race.lua',
    ['Fishing Chef']='fishing-chef.lua',
    ['Fishing Wars']='fishing-wars.lua',
    ['Hatch And Fry!']='hatch-and-fry.lua',
    ['Magnet Fishing']='magnet-fishing.lua',
    ['Merge a Squishy']='merge-a-squishy.lua',
    ['Project Aura RNG']='project-aura-rng.lua',
    ['Rescue Animals!']='rescue-animals.lua',
    ['Roll a Sorcerer']='roll-a-sorcerer.lua',
    ['RUNAWAYS']='runaways.lua',
    ['Steal A Lucky Egg']='steal-a-lucky-egg.lua',
    ['+1 Long Arm Toy Escape!']='1-long-arm-toy-escape.lua',
    ['+1 Power Jujutsu Kaisen Evolution']='1-power-jujutsu-kaisen-evolution.lua',
    ['+1 Speedster Escape']='1-speedster-escape.lua',
    ['+1 Spider Evolution']='1-spider-evolution.lua',
    ['+1 Sword Fighting Escape']='1-sword-fighting-escape.lua',
    ['Basketball Dynasty']='basketball-dynasty.lua',
    ['Break For Anime!']='break-for-anime.lua',
    ['Farmers Market!']='farmers-market.lua',
    ['Jump To Steal SCP Monsters!']='jump-to-steal-scp-monsters.lua',
    ['Pop & Collect']='pop-bubbles.lua',
    ['Roll Anime & Fight']='roll-anime-fight.lua',

}
-- Audited direct ports are explicit exceptions; other VM-protected sources are unchanged.
local directPorts={
    ['Grau SP']={file='grau-sp.lua',marker='-- Prime Void Hub | GRAU SP | v'},
    ['War Tycoon']={file='war-tycoon.lua',marker='-- Prime Void Hub | War Tycoon | v0.1.1'},
    ['Clover Legends']={file='clover.lua',marker='-- Prime Void Hub | Clover Legends: Devil Fusion | v0.1.11'},
    ['RIVALS']={file='rivals.lua',marker='-- Prime Void Hub | RIVALS | v0.1.2'},
    ['Da Hood']={file='da-hood.lua',marker='-- Prime Void Hub | Da Hood | v0.1.1'},
    ['Roube um Espírito Santo']={file='spirit-sanctuary.lua',marker='-- Prime Void Hub | Roube um Espírito Santo | v0.1.9'},
}
local direct=directPorts[selected.name]
local obfuscatedFile=obfuscatedNames[selected.name]
if not direct and not obfuscatedFile then
    error('[PVH PORT] Unrecognized port: '..tostring(selected.name),0)
end
selected.url=direct
    and 'https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/'..direct.file
    or 'https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/'..obfuscatedFile
local ok,source=pcall(function()
    return game:HttpGet(selected.url..'?t='..tostring(os.time()))
end)
if not ok or type(source)~='string' or #source<800 then
    error('[PVH OBF] Download failed ('..selected.name..'): '..tostring(source),0)
end
if direct then
    if not source:find(direct.marker,1,true) then
        error('[PVH PORT] Unexpected direct module for '..selected.name,0)
    end
elseif not (source:find('-- Obscura [',1,true) or source:find('-- Obscura VM [',1,true)) then
    error('[PVH OBF] Expected protected Obscura source for '..selected.name,0)
end

-- Universal session policy (Auto Save + teleport Autoexec).
-- Kept independent from gameplay sources, so new Obsidian ports inherit it.
local previousPersistence=genv.PVH_Persistence
if type(previousPersistence)=='table' and type(previousPersistence.Stop)=='function' then
    pcall(function()previousPersistence:Stop()end)
end
genv.PVH_Persistence=nil
local persistence
local persistenceOK,persistenceResult=pcall(function()
    local moduleURL='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Persistence.lua'
    local body=game:HttpGet(moduleURL..'?pvht='..tostring(os.time()))
    local factory,loadErr=loadstring(body)
    if not factory then error(loadErr) end
    local constructor=factory()
    if type(constructor)~='function' then error('Persistence constructor unavailable') end
    local nativeFiles={
        ['Storm Suite']='primevoid_hub/Storm_Suite/Config/settings.json',
        ['Exu Security Lab']='primevoid_hub/Exu_Security_Lab/Configs/ui_settings.json',
        ['Huntress']='primevoid_hub/Huntress/Configs/ui_settings.json',
        ['Dont Splash Explorer']='primevoid_hub/Dont_Splash/Configs/ui_settings.json',
        ['Destruction Simulator']='primevoid_hub/Destruction_Simulator/Configs/ui_settings.json',
        ['Grau SP']='primevoid_hub/Grau_SP/Configs/settings.json',
        ['War Tycoon']='primevoid_hub/War_Tycoon/Configs/ui_settings.json',
        ['Clover Legends']='primevoid_hub/Clover_Legends/Configs/ui_settings.json',
        ['Steal a Brainrot']='primevoid_hub/Steal_Brainrot/Configs/ui_settings.json',
        ['RIVALS']='primevoid_hub/RIVALS/Configs/ui_settings.json',
        ['Da Hood']='primevoid_hub/Da_Hood/Configs/ui_settings.json',
        ['Roube um Espírito Santo']='primevoid_hub/Spirit_Sanctuary/Configs/ui_settings.json',
        ['Anime RNG Defense']='primevoid_hub/Anime_RNG_Defense/Configs/ui_settings.json',
        ['Chicken Farm']='primevoid_hub/Chicken_Farm/Configs/ui_settings.json',
        ['RATO']='primevoid_hub/RATO/Configs/settings.json',
        ['Spin a Car']='primevoid_hub/Spin_A_Car/Configs/ui_settings.json',
        ['Merge a Nuke!']='primevoid_hub/Merge_A_Nuke/Configs/ui_settings.json',
        ['Roll for Anime!']='primevoid_hub/Roll_For_Anime/Configs/ui_settings.json',
        ['Build a Keyboard']='primevoid_hub/Build_A_Keyboard/Configs/ui_settings.json',
        ['2omething evil will happen']='primevoid_hub/2omething_Evil/Configs/ui_settings.json',
        ['Make a Drill Farm']='primevoid_hub/Make_A_Drill_Farm/Configs/ui_settings.json',
        ['+1 Clone Evolution']='primevoid_hub/1-clone-evolution/Configs/ui_settings.json',
        ['+1 Dino Evolution']='primevoid_hub/1-dino-evolution/Configs/ui_settings.json',
        ['+1 DMG FPS']='primevoid_hub/1-dmg-fps/Configs/ui_settings.json',
        ['+1 Fart to Break Doors']='primevoid_hub/1-fart-to-break-doors/Configs/ui_settings.json',
        ['+1 Mog Evolution']='primevoid_hub/1-mog-evolution/Configs/ui_settings.json',
        ['+1 Slash Per Click!']='primevoid_hub/1-slash-per-click/Configs/ui_settings.json',
        ['+1 Stone Skipping']='primevoid_hub/1-stone-skipping/Configs/ui_settings.json',
        ['+1 Strength for Eggs']='primevoid_hub/1-strength-for-eggs/Configs/ui_settings.json',
        ['+1 Sword vs Anime']='primevoid_hub/1-sword-vs-anime/Configs/ui_settings.json',
        ['+1 TNT Mining']='primevoid_hub/1-tnt-mining/Configs/ui_settings.json',
        ['+1 Chop Tree and Ride Pet']='primevoid_hub/1-cut-and-ride-pet/Configs/ui_settings.json',
        ['+1 Tongue Escape']='primevoid_hub/1-tongue-escape/Configs/ui_settings.json',
        ['Anomaly Garden']='primevoid_hub/anomaly-garden/Configs/ui_settings.json',
        ['Become a Billionaire']='primevoid_hub/become-a-billionaire/Configs/ui_settings.json',
        ['Blow up Lucky Blocks For Cars']='primevoid_hub/blow-up-lucky-blocks-for-cars/Configs/ui_settings.json',
        ['Break an Egg!']='primevoid_hub/break-an-egg/Configs/ui_settings.json',
        ['Build Golems and Fight']='primevoid_hub/build-golems-and-fight/Configs/ui_settings.json',
        ['Collect 1 Million Items']='primevoid_hub/collect-1-million-items/Configs/ui_settings.json',
        ['Drive-Thru Empire']='primevoid_hub/drive-thru-empire/Configs/ui_settings.json',
        ['Fruit Zombie Survival']='primevoid_hub/fruit-zombie-survival/Configs/ui_settings.json',
        ['Jump To Steal An Egg']='primevoid_hub/jump-to-steal-an-egg/Configs/ui_settings.json',
        ['Lift a Cube']='primevoid_hub/lift-a-cube/Configs/ui_settings.json',
        ['Make Hotsauce']='primevoid_hub/make-hotsauce/Configs/ui_settings.json',
        ['Merge a Dino']='primevoid_hub/merge-a-dino/Configs/ui_settings.json',
        ['Motorcycle for Animals']='primevoid_hub/motorcycle-for-animals/Configs/ui_settings.json',
        ['My Anime Mine']='primevoid_hub/my-anime-mine/Configs/ui_settings.json',
        ['My Dino Park!']='primevoid_hub/my-dino-park/Configs/ui_settings.json',
        ['My Lucky Train']='primevoid_hub/my-lucky-train/Configs/ui_settings.json',
        ['Open Sea For Animals!']='primevoid_hub/open-sea-for-animals/Configs/ui_settings.json',
        ['Pets Universe!']='primevoid_hub/pets-universe/Configs/ui_settings.json',
        ['Race Horses']='primevoid_hub/race-horses/Configs/ui_settings.json',
        ['Roller for Animals!']='primevoid_hub/roller-for-animals/Configs/ui_settings.json',
        ['Sail For Eggs']='primevoid_hub/sail-for-eggs/Configs/ui_settings.json',
        ['Snowcone Stand']='primevoid_hub/snowcone-stand/Configs/ui_settings.json',
        ['Steal a Giant Egg']='primevoid_hub/steal-a-giant-egg/Configs/ui_settings.json',
        ['Backrooms Simulator']='primevoid_hub/backrooms-simulator/Configs/ui_settings.json',
        ['Beat the Anime Boss!']='primevoid_hub/beat-the-anime-boss/Configs/ui_settings.json',
        ['Brainrot Card Battles']='primevoid_hub/brainrot-card-battles/Configs/ui_settings.json',
        ['Choose the Stronger Anime!']='primevoid_hub/choose-the-stronger-anime/Configs/ui_settings.json',
        ['Collect Cars and Race']='primevoid_hub/collect-cars-and-race/Configs/ui_settings.json',
        ['Fishing Chef']='primevoid_hub/fishing-chef/Configs/ui_settings.json',
        ['Fishing Wars']='primevoid_hub/fishing-wars/Configs/ui_settings.json',
        ['Hatch And Fry!']='primevoid_hub/hatch-and-fry/Configs/ui_settings.json',
        ['Magnet Fishing']='primevoid_hub/magnet-fishing/Configs/ui_settings.json',
        ['Merge a Squishy']='primevoid_hub/merge-a-squishy/Configs/ui_settings.json',
        ['Project Aura RNG']='primevoid_hub/project-aura-rng/Configs/ui_settings.json',
        ['Rescue Animals!']='primevoid_hub/rescue-animals/Configs/ui_settings.json',
        ['Roll a Sorcerer']='primevoid_hub/roll-a-sorcerer/Configs/ui_settings.json',
        ['RUNAWAYS']='primevoid_hub/runaways/Configs/ui_settings.json',
        ['Steal A Lucky Egg']='primevoid_hub/steal-a-lucky-egg/Configs/ui_settings.json',
        ['+1 Long Arm Toy Escape!']='primevoid_hub/1-long-arm-toy-escape/Configs/ui_settings.json',
        ['+1 Power Jujutsu Kaisen Evolution']='primevoid_hub/1-power-jujutsu-kaisen-evolution/Configs/ui_settings.json',
        ['+1 Speedster Escape']='primevoid_hub/1-speedster-escape/Configs/ui_settings.json',
        ['+1 Spider Evolution']='primevoid_hub/1-spider-evolution/Configs/ui_settings.json',
        ['+1 Sword Fighting Escape']='primevoid_hub/1-sword-fighting-escape/Configs/ui_settings.json',
        ['Basketball Dynasty']='primevoid_hub/basketball-dynasty/Configs/ui_settings.json',
        ['Break For Anime!']='primevoid_hub/break-for-anime/Configs/ui_settings.json',
        ['Farmers Market!']='primevoid_hub/farmers-market/Configs/ui_settings.json',
        ['Jump To Steal SCP Monsters!']='primevoid_hub/jump-to-steal-scp-monsters/Configs/ui_settings.json',
        ['Pop & Collect']='primevoid_hub/pop-bubbles/Configs/ui_settings.json',
        ['Roll Anime & Fight']='primevoid_hub/roll-anime-fight/Configs/ui_settings.json',
    }
    local instance=constructor({
        port=selected.name,
        nativeConfig=nativeFiles[selected.name],
        loaderUrl='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua',
        carryAutoexec=carriedPort~=nil and carriedPort.name==selected.name and carry.autoexec==true,
        originUniverse=carriedPort and carriedPort.name==selected.name and carry.originUniverse or universeId,
    })
    instance:BeforePort()
    return instance
end)
if persistenceOK then
    persistence=persistenceResult
    genv.PVH_Persistence=persistence
else
    warn('[PVH Common] Persistence unavailable, port starts unchanged: '..tostring(persistenceResult))
end
-- When Auto Save is disabled, ignore legacy native settings.json on this run.
-- Named profiles and unrelated user files remain available to the port.
if persistence and persistence.AutoSave==false then
    local noLegacyConfig=[=[
local __pvh_isfile=isfile
local __pvh_readfile=readfile
local function __pvh_legacy_settings(path)
    if type(path)~='string' then return false end
    local normalized=path:gsub('\\','/')
    return normalized:match('/Config/settings%.json$')~=nil
        or normalized:match('/Configs/ui_settings%.json$')~=nil
end
local isfile=function(path)
    if __pvh_legacy_settings(path) then return false end
    return type(__pvh_isfile)=='function' and __pvh_isfile(path) or false
end
local readfile=function(path)
    if __pvh_legacy_settings(path) then
        error('PVH Auto Save disabled: default settings are used',0)
    end
    if type(__pvh_readfile)=='function' then return __pvh_readfile(path) end
    error('readfile unavailable',0)
end
]=]
    source=noLegacyConfig..source
end

-- Prepatched Exu sources include PVH_GIFTS_MAIN_UI but do not initialize
-- PVEXU_GiftsPrefs themselves. The normal loader initializes this object
-- BEFORE executing the port. Mirror that contract for the protected test.
if selected.name=='Exu Security Lab' then
    local giftEnv=(type(getgenv)=='function' and getgenv()) or _G
    local resumeGift=giftEnv.PVEXU_GiftsResume
    if type(giftEnv.PVEXU_GiftsPrefs)~='table' then
        giftEnv.PVEXU_GiftsPrefs={
            collect=type(resumeGift)=='table' and resumeGift.collect==true or false,
            hop=type(resumeGift)=='table' and resumeGift.hop==true or false,
        }
    end
end

local chunk,compileError=loadstring(source)
if not chunk then
    if not previousLog then genv.PV_Hub_AnalyticsSent=nil end
    error('[Prime Void Hub] Erro ao compilar '..selected.name..': '..tostring(compileError),0)
end
local success,runtimeError=pcall(chunk)
if not success then
    if not previousLog then genv.PV_Hub_AnalyticsSent=nil end
    error('[Prime Void Hub] Erro em '..selected.name..': '..tostring(runtimeError),0)
end
if persistence then
    local okPersist,errPersist=pcall(function()persistence:AfterPort()end)
    if not okPersist then warn('[PVH Common] Post-load error: '..tostring(errPersist)) end
end

-- Exu maintenance lock: load the normal protected port, but leave Auto Farm
-- visibly disabled. All other Obsidian controls retain their normal behavior.
-- Protect SetValue as well: universal Auto Save restores saved toggles asynchronously.
if selected.name=='Exu Security Lab' then
    local maintenanceText='UNDER MAINTENANCE — DETECTED'
    local function lockExuFarm()
        local lib=genv.Library
        if type(lib)~='table' or lib.Unloaded then return false end
        local toggles=lib.Toggles or genv.Toggles
        local farm=type(toggles)=='table' and toggles.PVEXU_AutoFarm or nil
        if type(farm)~='table' or type(farm.SetDisabled)~='function'
            or type(farm.SetValue)~='function' or typeof(farm.Holder)~='Instance' then
            return false
        end
        if farm.PVH_MaintenanceLocked then return true end
        farm.PVH_MaintenanceLocked=true

        local oldSetValue=farm.SetValue
        local oldSetDisabled=farm.SetDisabled
        local oldCallback=farm.Callback
        -- First stop any active farm before disabling UI callbacks.
        pcall(function() oldSetValue(farm,false) end)
        farm.Callback=function(value,...)
            if value==true then return end
            if type(oldCallback)=='function' then
                return oldCallback(value,...)
            end
        end
        farm.SetValue=function(self,value)
            if value==true then
                if self.Value==true then return oldSetValue(self,false) end
                return
            end
            return oldSetValue(self,false)
        end
        farm:SetDisabled(true)
        farm.SetDisabled=function(self,_) return oldSetDisabled(self,true) end
        pcall(function() farm:SetText('Auto Farm Exus [MAINTENANCE]') end)
        farm.Risky=true
        pcall(function()
            farm.TextLabel.TextColor3=Color3.fromRGB(255,105,105)
        end)

        -- A transparent child handles mouse hover and touchscreen taps.
        -- The toggle itself stays disabled by Obsidian and cannot be activated.
        local overlay=Instance.new('TextButton')
        overlay.Name='PVH_ExuFarmMaintenance'
        overlay.BackgroundTransparency=1
        overlay.BorderSizePixel=0
        overlay.Text=''
        overlay.AutoButtonColor=false
        overlay.Active=true
        overlay.Selectable=false
        overlay.Size=UDim2.fromScale(1,1)
        overlay.Position=UDim2.fromScale(0,0)
        overlay.ZIndex=farm.Holder.ZIndex+5
        overlay.Parent=farm.Holder
        local okTooltip,tooltip=pcall(function()
            return lib:AddTooltip(nil,maintenanceText,overlay)
        end)
        if okTooltip and type(tooltip)=='table' then
            tooltip.Disabled=true
        end
        overlay.Activated:Connect(function()
            pcall(function()
                lib:Notify({Title='Prime Void Hub',Description=maintenanceText,Time=5})
            end)
        end)
        warn('[PVH Exu] Auto Farm disabled: '..maintenanceText)
        return true
    end

    local locked=false
    for _=1,30 do
        local ok,result=pcall(lockExuFarm)
        if ok and result then locked=true break end
        task.wait(0.1)
    end
    if not locked then
        -- Fail closed: do not leave an accessible Auto Farm when the UI changed.
        warn('[PVH Exu] Maintenance lock unavailable; refusing to enable this port.')
        pcall(function()
            if type(genv.Library)=='table' then genv.Library:Unload() end
        end)
        return
    end
end

-- Exu no-eligible-target hop override. UI stays in the existing Farm panel.
-- Protected Obscura sources are left untouched; the old loop is disabled.
if selected.name=='Exu Security Lab' then
    task.spawn(function()
        local okHop,errHop=pcall(function()
            local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_ExuAutoHop.lua'
            local chunk,compileError=loadstring(game:HttpGet(url..'?t='..tostring(os.time())))
            if not chunk then error(compileError) end
            local setup=chunk()
            if type(setup)=='function' then setup() end
        end)
        if not okHop then warn('[PVH EXU HOP] initialization failed: '..tostring(errHop)) end
    end)
end

-- Safe integrated read-only feature diagnostics.
-- Does not enable Auto Farm, TP, combat, ESP or any gameplay feature.
task.spawn(function()
    local okChecker,errChecker=pcall(function()
        local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Checker.lua'
        local chunk,err=loadstring(game:HttpGet(url..'?t='..tostring(os.time())))
        if not chunk then error(err) end
        local construct=chunk()
        if type(construct)=='function' then construct(selected.name) end
    end)
    if not okChecker then warn('[PVH CHECKER] initialization failed: '..tostring(errChecker)) end
end)

-- Shared PT-BR/EN localization for legacy UI labels across every port.
-- The port's saved language remains authoritative; no new language setting.
task.spawn(function()
    local okLocale,errLocale=pcall(function()
        local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Locale.lua'
        local chunk,compileErr=loadstring(game:HttpGet(url..'?t='..tostring(os.time())))
        if not chunk then error(compileErr) end
        local setup=chunk()
        if type(setup)=='function' then setup(selected.name) end
    end)
    if not okLocale then warn('[PVH Locale] initialization: '..tostring(errLocale)) end
end)

-- PVH_UX_UNIVERSAL_V1 - all supported ports: mobile restore, native minus, player avatar.
-- Only touches runtime UI instances. Never modifies fetched or obfuscated sources.
do
    local uxPort = selected.name
    local previousUxCleanup = genv.PVH_UX_UniversalCleanup
    if type(previousUxCleanup) == 'function' then
        pcall(previousUxCleanup)
    end
    genv.PVH_UX_UniversalCleanup = nil

    if type(uxPort) == 'string' then
        task.spawn(function()
            local okUx, errUx = pcall(function()
                local PlayersUX = game:GetService('Players')
                local UISUX = game:GetService('UserInputService')
                local localPlayerUX = PlayersUX.LocalPlayer
                if not localPlayerUX then return end

                local libraryUX, mainUX
                local usedGuiFallbackUX = false
                local function activateGuiFallback(screen, main)
                    if typeof(screen) ~= 'Instance' or not screen:IsA('ScreenGui')
                        or typeof(main) ~= 'Instance' or not main:IsA('GuiObject')
                        or not main.Parent or not screen.Parent then
                        return false
                    end
                    mainUX = main
                    usedGuiFallbackUX = true
                    libraryUX = {
                        ScreenGui = screen,
                        Window = { MainFrame = main },
                        Toggled = main.Visible,
                        Animations = { ToggleWindow = false },
                    }
                    function libraryUX.Window:Toggle(value)
                        local show
                        if typeof(value) == 'boolean' then
                            show = value
                        else
                            show = not libraryUX.Toggled
                        end
                        main.Visible = show
                        libraryUX.Toggled = show
                    end
                    function libraryUX:Toggle(value)
                        return self.Window:Toggle(value)
                    end
                    return true
                end

                local function findNativeObsidian()
                    local roots = {}
                    local pg = localPlayerUX:FindFirstChildOfClass('PlayerGui')
                    if pg then roots[#roots+1] = pg end
                    local okCore, core = pcall(function()
                        return game:GetService('CoreGui')
                    end)
                    if okCore and core then roots[#roots+1] = core end
                    local okHui, hui = pcall(function()
                        return type(gethui) == 'function' and gethui() or nil
                    end)
                    if okHui and typeof(hui) == 'Instance' then
                        roots[#roots+1] = hui
                    end
                    for _, root in ipairs(roots) do
                        local okDesc, descendants = pcall(function()
                            return root:GetDescendants()
                        end)
                        if okDesc and type(descendants) == 'table' then
                            for _, screen in ipairs(descendants) do
                                if screen:IsA('ScreenGui') and screen.Name == 'Obsidian'
                                    and screen.Parent then
                                    local main = screen:FindFirstChild('Main')
                                    if main and main:IsA('GuiObject') and main.Parent then
                                        return screen, main
                                    end
                                end
                            end
                        end
                    end
                    return nil, nil
                end

                for attempt = 1, 100 do
                    if genv.PV_Hub_ActivePort ~= uxPort then return end
                    local candidate = genv.Library
                    local destructionGui = uxPort == 'Destruction Simulator'
                        and genv.PVDS_ScreenGui or nil
                    local validLibrary = type(candidate) == 'table'
                        and not candidate.Unloaded
                        and typeof(candidate.ScreenGui) == 'Instance'
                        and type(candidate.Window) == 'table'
                        and typeof(candidate.Window.MainFrame) == 'Instance'
                        and candidate.ScreenGui.Parent
                        and candidate.Window.MainFrame.Parent
                    if validLibrary and (not destructionGui
                        or candidate.ScreenGui == destructionGui) then
                        libraryUX = candidate
                        mainUX = candidate.Window.MainFrame
                        break
                    end
                    if uxPort == 'Destruction Simulator'
                        and typeof(destructionGui) == 'Instance'
                        and destructionGui:IsA('ScreenGui')
                        and destructionGui.Parent then
                        local nativeMain = destructionGui:FindFirstChild('Main', true)
                        if nativeMain and activateGuiFallback(destructionGui, nativeMain) then
                            break
                        end
                    end
                    if attempt % 4 == 1 then
                        local visualGui, visualMain = findNativeObsidian()
                        if visualGui and activateGuiFallback(visualGui, visualMain) then
                            break
                        end
                    end
                    task.wait(0.12)
                end
                if not libraryUX or not mainUX then
                    warn('[PVH UX UNIVERSAL] Obsidian window not found for '..uxPort..
                        ' | PVDS_ScreenGui='..tostring(typeof(genv.PVDS_ScreenGui)))
                    return
                end
                if usedGuiFallbackUX then
                    warn('[PVH UX UNIVERSAL] GUI compatibility fallback: '..uxPort)
                end
                -- Obsidian compares Input.KeyCode to ToggleKeybind. Mouse clicks
                -- report KeyCode.Unknown, so Unknown is never a valid disable key.
                if libraryUX.ToggleKeybind == Enum.KeyCode.Unknown then
                    libraryUX.ToggleKeybind = nil
                    warn('[PVH UX UNIVERSAL] Removed invalid Unknown toggle bind for '..uxPort)
                end

                local connections = {}
                local gone = false
                local cleanup
                local function listen(signal, callback)
                    local connection = signal:Connect(callback)
                    connections[#connections + 1] = connection
                    return connection
                end
                local playerGuiUX = localPlayerUX:FindFirstChildOfClass('PlayerGui')
                    or localPlayerUX:WaitForChild('PlayerGui', 5)
                local oldToggle = libraryUX.Window.Toggle
                local wrappedToggle
                local miniGui
                local headerButton
                local avatarButton
                local watched = {}
                -- PVH_HOME_ROSTER_V2: restore the previous Home rows on re-run.
                local rosterOriginalVisible = {}
                local rosterOriginalText = {}
                local rosterCreated = {}
                local rosterContainer = nil
                local cloverPortrait = nil

                cleanup = function()
                    if gone then return end
                    gone = true
                    for _, connection in ipairs(connections) do
                        pcall(function() connection:Disconnect() end)
                    end
                    for node, originalVisible in pairs(watched or {}) do
                        if typeof(node) == 'Instance' and node.Parent then
                            pcall(function() node.Visible = originalVisible end)
                        end
                    end
                    for _, row in ipairs(rosterCreated) do
                        pcall(function() row:Destroy() end)
                    end
                    for node, originalVisible in pairs(rosterOriginalVisible) do
                        if typeof(node) == 'Instance' and node.Parent then
                            pcall(function() node.Visible = originalVisible end)
                        end
                    end
                    for node, originalText in pairs(rosterOriginalText) do
                        if typeof(node) == 'Instance' and node.Parent then
                            pcall(function() node.Text = originalText end)
                        end
                    end
                    if libraryUX.Window and libraryUX.Window.Toggle == wrappedToggle then
                        libraryUX.Window.Toggle = oldToggle
                    end
                    if miniGui then pcall(function() miniGui:Destroy() end) end
                    if headerButton then pcall(function() headerButton:Destroy() end) end
                    if cloverPortrait then pcall(function() cloverPortrait:Destroy() end) end
                    if genv.PVH_UX_UniversalCleanup == cleanup then
                        genv.PVH_UX_UniversalCleanup = nil
                    end
                end
                genv.PVH_UX_UniversalCleanup = cleanup

                if type(libraryUX.Animations) == 'table' then
                    libraryUX.Animations.ToggleWindow = false
                end

                -- Independent ScreenGui: the Obsidian overlay cannot swallow mobile taps.
                miniGui = Instance.new('ScreenGui')
                miniGui.Name = 'PVH_UniversalMobileRestore'
                miniGui.IgnoreGuiInset = true
                miniGui.ResetOnSpawn = false
                miniGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                miniGui.DisplayOrder = math.max(10000, libraryUX.ScreenGui.DisplayOrder + 50)
                miniGui.Parent = libraryUX.ScreenGui.Parent

                avatarButton = Instance.new('ImageButton')
                avatarButton.Name = 'PVH_RestoreAvatar'
                avatarButton.BackgroundColor3 = Color3.fromRGB(31, 27, 43)
                avatarButton.BorderSizePixel = 0
                avatarButton.Size = UDim2.fromOffset(54, 54)
                avatarButton.Position = UDim2.new(0, 18, 0.5, -27)
                avatarButton.Visible = false
                avatarButton.Active = true
                avatarButton.AutoButtonColor = true
                avatarButton.ScaleType = Enum.ScaleType.Crop
                avatarButton.Image = string.format(
                    'rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150',
                    localPlayerUX.UserId
                )
                avatarButton.Parent = miniGui
                local avatarCorner = Instance.new('UICorner')
                avatarCorner.CornerRadius = UDim.new(0, 13)
                avatarCorner.Parent = avatarButton

                task.spawn(function()
                    for _ = 1, 4 do
                        if gone or not avatarButton.Parent then return end
                        local ok, image, ready = pcall(function()
                            return PlayersUX:GetUserThumbnailAsync(
                                localPlayerUX.UserId,
                                Enum.ThumbnailType.HeadShot,
                                Enum.ThumbnailSize.Size150x150
                            )
                        end)
                        if ok and ready and type(image) == 'string' and image ~= '' then
                            avatarButton.Image = image
                            return
                        end
                        task.wait(0.75)
                    end
                end)

                -- The rightmost ~49 px of the native Obsidian title bar are unused.
                headerButton = Instance.new('TextButton')
                headerButton.Name = 'PVH_HeaderMinimize'
                headerButton.AnchorPoint = Vector2.new(1, 0)
                headerButton.Position = UDim2.new(1, -12, 0, 10)
                headerButton.Size = UDim2.fromOffset(29, 27)
                headerButton.BackgroundTransparency = 1
                headerButton.TextColor3 = Color3.fromRGB(198, 195, 208)
                headerButton.Text = '−'
                headerButton.Font = Enum.Font.GothamMedium
                headerButton.TextSize = 20
                headerButton.AutoButtonColor = true
                headerButton.Active = true
                headerButton.ZIndex = 50
                headerButton.Parent = mainUX

                -- The Obsidian's MoveIcon is an ImageLabel under TopBar.
                -- Search by its unique right-edge position instead of the
                -- TopBar's exact Size (which can change at runtime).
                -- MoveIcon is decorative: do not disable TopBar dragging.
                local function hideObsidianMoveIcon()
                    for _, candidate in ipairs(mainUX:GetDescendants()) do
                        if candidate:IsA('ImageLabel')
                            and candidate.AnchorPoint == Vector2.new(1, 0.5)
                            and candidate.Position.X.Scale == 1
                            and candidate.Position.X.Offset == -10
                            and candidate.Position.Y.Scale == 0.5
                            and candidate.Size.X.Offset <= 34
                            and candidate.Size.Y.Offset <= 34
                            and candidate:IsDescendantOf(mainUX)
                            and candidate.Parent
                            and candidate.Parent:IsA('GuiObject') then
                            candidate.Visible = false
                            -- Place our minus inside the native TopBar, exactly
                            -- where the arrows used to be (same layout on mobile).
                            if headerButton.Parent ~= candidate.Parent then
                                headerButton.Parent = candidate.Parent
                            end
                            headerButton.AnchorPoint = Vector2.new(1, 0.5)
                            headerButton.Position = UDim2.new(1, -10, 0.5, 0)
                            headerButton.Size = UDim2.fromOffset(28, 28)
                            headerButton.ZIndex = math.max(50, candidate.ZIndex + 1)
                            return true
                        end
                    end
                    return false
                end
                if not hideObsidianMoveIcon() then
                    warn('[PVH UX UNIVERSAL] Icone move da Obsidian nao encontrado para ocultar')
                end

                -- Keep the old mini launchers hidden so a single avatar works
                -- across all supported ports, including ports with different UI names.
                local function oldLauncher(node)
                    if not node or not node:IsA('GuiButton')
                        or node == avatarButton or node == headerButton
                        or node:IsDescendantOf(mainUX) then
                        return false
                    end
                    local name = node.Name:lower()
                    local screen = node:FindFirstAncestorOfClass('ScreenGui')
                    if not screen then return false end
                    local screenName = screen.Name:lower()
                    local portScreen = screen == libraryUX.ScreenGui
                        or screenName:find('prime',1,true)
                        or screenName:find('pvh',1,true)
                        or screenName:find('pvds',1,true)
                        or screenName:find('storm',1,true)
                        or screenName:find('huntress',1,true)
                        or screenName:find('clover',1,true)
                        or screenName:find('splash',1,true)
                        or screenName:find('exu',1,true)
                        or screenName:find('destruction',1,true)
                    if not portScreen then return false end
                    if node:FindFirstChild('PVHubMiniAvatar')
                        or node:FindFirstChild('GitHubAvatar') then return true end
                    local known = name == 'stormmini' or name == 'pvhubmini'
                        or name == 'miniicon' or name == 'iconbutton'
                        or name:find('minimizeicon',1,true)
                        or name:find('minimizedicon',1,true)
                        or name:find('floatingicon',1,true)
                    if not known then
                        known = name:find('mini',1,true)
                            or name:find('floating',1,true)
                    end
                    if not known then return false end
                    local size = node.AbsoluteSize
                    local w = size.X > 0 and size.X or node.Size.X.Offset
                    local h = size.Y > 0 and size.Y or node.Size.Y.Offset
                    return w <= 100 and h <= 100 and w >= 20 and h >= 20
                end
                local function suppressOne(node)
                    if not oldLauncher(node) or watched[node] ~= nil then return end
                    watched[node] = node.Visible
                    node.Visible = false
                    listen(node:GetPropertyChangedSignal('Visible'), function()
                        if not gone and node.Parent and node.Visible then
                            node.Visible = false
                        end
                    end)
                end
                local function suppressLegacy(root)
                    if typeof(root) ~= 'Instance' then return end
                    suppressOne(root)
                    local okDesc, descendants = pcall(function()
                        return root:GetDescendants()
                    end)
                    if okDesc and type(descendants) == 'table' then
                        for _, node in ipairs(descendants) do
                            suppressOne(node)
                        end
                    end
                end


                -- The loader owns the canonical port list; legacy ports may
                -- still draw only 2 or 3 items. Change just this Home groupbox,
                -- not gameplay, library sources, or other Home groupboxes.
                local function findPortsGroupContainer()
                    if not libraryUX.ScreenGui or not libraryUX.ScreenGui.Parent then
                        return nil
                    end
                    for _, label in ipairs(libraryUX.ScreenGui:GetDescendants()) do
                        if label:IsA('TextLabel') and type(label.Text) == 'string' then
                            local title = label.Text:lower()
                            local isPortsHeader = (title:find('ports',1,true)
                                and (title:find('dispon',1,true)
                                    or title:find('available',1,true)))
                                or title:find('jogos suportados',1,true)
                                or title:find('supported games',1,true)
                            if isPortsHeader then
                                local textFrame = label.Parent
                                local topBar = textFrame and textFrame.Parent
                                local groupHolder = topBar and topBar.Parent
                                if groupHolder and groupHolder:IsA('Frame')
                                    and topBar:IsA('Frame') then
                                    for _, child in ipairs(groupHolder:GetChildren()) do
                                        if child:IsA('ScrollingFrame')
                                            and child.LayoutOrder == 2 then
                                            return child
                                        end
                                    end
                                end
                            end
                        end
                    end
                    return nil
                end

                local function removeDestructionTestLabels()
                    if uxPort ~= 'Destruction Simulator' then return end
                    for _, node in ipairs(libraryUX.ScreenGui:GetDescendants()) do
                        if node:IsA('TextLabel')
                            and node.Text:find('Destruction Simulator',1,true)
                            and node.Text:find('TEST',1,true) then
                            if rosterOriginalText[node] == nil then
                                rosterOriginalText[node] = node.Text
                            end
                            -- Only visual labels: never modify the signed or
                            -- obfuscated source, logs, or feature names.
                            local clean = node.Text:gsub(' — TEST','')
                                :gsub(' %- TEST','')
                                :gsub(' TEST','')
                            node.Text = clean
                        end
                    end
                end

                local function updateHomeRoster()
                    if gone or not mainUX.Parent then return false end
                    local container = findPortsGroupContainer()
                    if not container then return false end
                    if rosterContainer == container and #rosterCreated == #ports
                        and rosterCreated[1] and rosterCreated[1].Parent == container then
                        return true
                    end

                    -- Rebuild atomically if the UI was recreated.
                    for _, row in ipairs(rosterCreated) do
                        pcall(function() row:Destroy() end)
                    end
                    table.clear(rosterCreated)
                    for label, visible in pairs(rosterOriginalVisible) do
                        if label.Parent then label.Visible = visible end
                    end
                    table.clear(rosterOriginalVisible)

                    local sample = nil
                    for _, node in ipairs(container:GetChildren()) do
                        if node:IsA('TextLabel') then
                            if not sample then sample = node end
                            rosterOriginalVisible[node] = node.Visible
                            node.Visible = false
                        end
                    end

                    for index, port in ipairs(ports) do
                        local row = Instance.new('TextLabel')
                        row.Name = 'PVH_HomePort_'..tostring(index)
                        row.BackgroundTransparency = 1
                        row.BorderSizePixel = 0
                        row.Size = UDim2.new(1, 0, 0, 18)
                        row.TextSize = sample and sample.TextSize or 14
                        row.FontFace = sample and sample.FontFace
                            or Font.fromEnum(Enum.Font.Code)
                        row.TextColor3 = sample and sample.TextColor3
                            or Color3.fromRGB(235, 235, 235)
                        row.TextTransparency = sample and sample.TextTransparency or 0
                        row.TextXAlignment = Enum.TextXAlignment.Left
                        row.TextYAlignment = Enum.TextYAlignment.Center
                        row.TextWrapped = false
                        row.LayoutOrder = 100 + index
                        local dot = port.name == 'Dont Splash Explorer' and '🟡' or '🟢'
                        row.Text = dot..port.officialName
                        row.Parent = container
                        rosterCreated[#rosterCreated + 1] = row
                    end
                    rosterContainer = container
                    removeDestructionTestLabels()
                    return true
                end

                task.spawn(function()
                    for attempt = 1, 100 do
                        if gone or genv.PV_Hub_ActivePort ~= uxPort then return end
                        local okRoster, updated = pcall(updateHomeRoster)
                        if okRoster and updated then
                            warn('[PVH HOME] Roster synced ('..tostring(#ports)..' ports): '..uxPort)
                            return
                        end
                        if not okRoster and attempt == 1 then
                            warn('[PVH HOME] Roster scan: '..tostring(updated))
                        end
                        task.wait(0.12)
                    end
                    warn('[PVH HOME] Ports group not found: '..uxPort)
                end)

                -- Clover's Home account card gets the same player portrait used
                -- by the universal minimize/restore avatar. Safe no-op on other ports.
                if uxPort == 'Clover Legends' then
                    task.spawn(function()
                        for _=1,50 do
                            if gone or not libraryUX.ScreenGui or not libraryUX.ScreenGui.Parent then return end
                            if cloverPortrait and cloverPortrait.Parent then return end
                            for _, label in ipairs(libraryUX.ScreenGui:GetDescendants()) do
                                if label:IsA('TextLabel')
                                    and (label.Text == 'Conta' or label.Text == 'Account') then
                                    local titleFrame = label.Parent
                                    local topBar = titleFrame and titleFrame.Parent
                                    local groupHolder = topBar and topBar.Parent
                                    if groupHolder and groupHolder:IsA('Frame') then
                                        for _, area in ipairs(groupHolder:GetChildren()) do
                                            if area:IsA('ScrollingFrame') and area.LayoutOrder == 2 then
                                                local portrait = Instance.new('ImageLabel')
                                                portrait.Name = 'PVH_CloverAccountAvatar'
                                                portrait.BackgroundTransparency = 1
                                                portrait.BorderSizePixel = 0
                                                portrait.Size = UDim2.fromOffset(64,64)
                                                portrait.LayoutOrder = -50
                                                portrait.ScaleType = Enum.ScaleType.Crop
                                                portrait.Image = string.format(
                                                    'rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150',
                                                    localPlayerUX.UserId
                                                )
                                                local corner = Instance.new('UICorner')
                                                corner.CornerRadius = UDim.new(0,10)
                                                corner.Parent = portrait
                                                portrait.Parent = area
                                                cloverPortrait = portrait
                                                return
                                            end
                                        end
                                    end
                                end
                            end
                            task.wait(0.15)
                        end
                    end)
                end

                local function sync()
                    if gone or not mainUX.Parent then return end
                    if usedGuiFallbackUX then
                        libraryUX.Toggled = mainUX.Visible
                    end
                    suppressLegacy(libraryUX.ScreenGui)
                    suppressLegacy(playerGuiUX)
                    suppressLegacy(libraryUX.ScreenGui.Parent)
                    avatarButton.Visible = (libraryUX.Toggled ~= true) or not mainUX.Visible
                end

                -- Storm currently tracks a separate "minimized" flag. If that flag
                -- desynchronizes after using this button, treat the next explicit
                -- Window:Toggle(boolean) request as a toggle, not a no-op.
                wrappedToggle = function(self, desired)
                    if type(libraryUX.Animations) == 'table' then
                        libraryUX.Animations.ToggleWindow = false
                    end
                    if uxPort == 'Storm Suite' and type(desired) == 'boolean'
                        and desired == libraryUX.Toggled then
                        desired = not desired
                    end
                    local result = oldToggle(self, desired)
                    task.defer(sync)
                    return result
                end
                libraryUX.Window.Toggle = wrappedToggle

                listen(headerButton.Activated, function()
                    if gone then return end
                    libraryUX:Toggle(false)
                    sync()
                end)
                listen(avatarButton.Activated, function()
                    if gone or not avatarButton.Parent then return end
                    if avatarButton:GetAttribute('PVH_JustDragged') then return end
                    libraryUX:Toggle(true)
                    if libraryUX.Toggled == true and mainUX.Parent then
                        mainUX.Visible = true
                    end
                    sync()
                end)

                -- Touch/mouse dragging with pointer release anywhere on screen.
                local drag, origin, originalPosition, dragged
                local function release(input)
                    if not drag then return end
                    if drag.UserInputType == Enum.UserInputType.Touch then
                        if input ~= drag then return end
                    elseif input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end
                    drag = nil
                    origin = nil
                    originalPosition = nil
                    if dragged then
                        avatarButton:SetAttribute('PVH_JustDragged', true)
                        task.delay(0.25, function()
                            if not gone and avatarButton.Parent then
                                avatarButton:SetAttribute('PVH_JustDragged', false)
                            end
                        end)
                    end
                end
                listen(avatarButton.InputBegan, function(input)
                    if input.UserInputType ~= Enum.UserInputType.Touch
                        and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end
                    drag = input
                    origin = input.Position
                    originalPosition = avatarButton.Position
                    dragged = false
                    avatarButton:SetAttribute('PVH_JustDragged', false)
                end)
                listen(UISUX.InputChanged, function(input)
                    if not drag or not origin or not originalPosition then return end
                    if drag.UserInputType == Enum.UserInputType.Touch then
                        if input ~= drag then return end
                    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
                        return
                    end
                    local delta = input.Position - origin
                    if delta.Magnitude >= 10 then
                        dragged = true
                        avatarButton:SetAttribute('PVH_JustDragged', true)
                    end
                    if not dragged then return end
                    local parentSize = workspace.CurrentCamera
                        and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
                    local x = originalPosition.X.Scale * parentSize.X
                        + originalPosition.X.Offset + delta.X
                    local y = originalPosition.Y.Scale * parentSize.Y
                        + originalPosition.Y.Offset + delta.Y
                    x = math.clamp(x, 0, math.max(0, parentSize.X - avatarButton.AbsoluteSize.X))
                    y = math.clamp(y, 0, math.max(0, parentSize.Y - avatarButton.AbsoluteSize.Y))
                    avatarButton.Position = UDim2.fromOffset(x, y)
                end)
                listen(UISUX.InputEnded, release)
                listen(UISUX.WindowFocusReleased, function()
                    drag = nil
                    origin = nil
                    originalPosition = nil
                end)

                listen(mainUX:GetPropertyChangedSignal('Visible'), function()
                    task.defer(sync)
                end)
                listen(libraryUX.ScreenGui.DescendantAdded, function(node)
                    task.defer(function() suppressLegacy(node) end)
                end)
                if playerGuiUX then
                    listen(playerGuiUX.DescendantAdded, function(node)
                        task.defer(function() suppressLegacy(node) end)
                    end)
                end
                listen(libraryUX.ScreenGui.Destroying, cleanup)
                sync()
                warn('[PVH UX UNIVERSAL] Header − and mobile avatar installed: '..uxPort)
            end)
            if not okUx then
                warn('[PVH UX UNIVERSAL] setup failed: '..tostring(errUx))
            end
        end)
    end
end

-- The universal analytics launch attempt is already queued before
-- the gameplay module is fetched, regardless of port.


-- Prime Void Hub | Exu gift runtime (no extra windows, no Halloween changes).
-- The primary farm UI is already loaded; this module cannot break the Hub boot.
if selected.name=='Exu Security Lab' then
    task.spawn(function()
        local ok,err=pcall(function()
            local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/exu-gifts.lua'
            local body=game:HttpGet(url)
            -- The protected gifts runtime owns its queue on an intentional gift hop.
            -- Redirect only its loader URL to this already-existing TEST loader.
            -- Do not queue anything at boot or on a voluntary manual join.
            local queueShim=[=[
local __pvhLegacyQueue=(type(queue_on_teleport)=='function' and queue_on_teleport)
    or (type(syn)=='table' and syn.queue_on_teleport)
    or (type(fluxus)=='table' and fluxus.queue_on_teleport)
local queue_on_teleport=type(__pvhLegacyQueue)=='function' and function(payload)
    if type(payload)=='string' then
        payload=payload:gsub(
            'https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua',
            'https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua'
        )
    end
    return __pvhLegacyQueue(payload)
end or nil
]=]
            local fn,compileError=loadstring(queueShim..body)
            if not fn then error('Gift engine syntax: '..tostring(compileError)) end
            fn()
        end)
        if not ok then warn('[PVH GIFTS] Runtime unavailable: '..tostring(err)) end
    end)
end
