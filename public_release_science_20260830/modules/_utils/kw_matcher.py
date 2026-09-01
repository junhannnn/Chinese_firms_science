def country_name_match(input_string):
    import re

    country_match = {
        'USA': [
            r'USA',
            r'US',
            r'U\.S\.',
            r'U\.S\.A',
            r'United States'
        ],
        'Mexico': [
            r'Mexico',
            r'México',
            r'Mexican',
            r'Mexicanos'
        ],
        'Taiwan': [
            r'Taiwan',
            r'臺灣',
            r'Taipei'
        ],
        'Hong Kong': [
            r'Hong Kong',
            r'香港',
            r'HKSAR'
        ],
        'Macau': [
            r'Macau',
            r'澳門',
            r'澳门'
        ],
        'Japan': [
            r'Japan',
            r'Nippon',
            r'日本',
            r'[\u3040-\u30FF\u31F0-\u31FF]+'
        ],
        'China': [
            r'[\u4E00-\u9FFF]+',
            r'China'
        ],
        'South Korea': [
            r'South Korea',
            r'Korea',
            r'대한민국',
            r'[\uAC00-\uD7AF]+'
        ],
        'Israel': [
            r'Israel',
            r'ישראל',
            r'[\u0590-\u05FF]+'
        ],
        'Iran': [
            r'Iran',
            r'ایران',
            r'[\u0600-\u06FF]+'
        ],
        'India': [
            r'India',
            r'Bharat',
            r'Hindustan',
            r'भारत',
            r'[\u0900-\u097F]+'
        ],
        'Thailand': [
            r'Thailand',
            r'ประเทศไทย',
            r'[\u0E00-\u0E7F]+'
        ],
        'Germany': [
            r'Germany',
            r'Deutschland'
        ],
        'France': [
            r'France',
            r'française'
        ],
        'Canada': [
            r'Canada',
            r'Canadian'
        ],
        'Australia': [
            r'Australia'
        ],
        'Brazil': [
            r'Brazil',
            r'Brasil'
        ],
        'South Africa': [
            r'South\.?Africa'
        ],
        'Italy': [
            r'Italy',
            r'Italia[n]?',
            r'italiana'
        ],
        'Spain': [
            r'Spain',
            r'España'
        ],
        'Vietnam': [
            r'Vietnam',
            r'Việt Nam'
        ],
        'Norway': [
            r'Norway',
            r'Norge',
            r'Noreg'
        ],
        'Myanmar': [
            r'Myanmar',
            r'Burma',
            r'မြန်မာ'
        ],
        'Romania': [
            r'Romania',
            r'România'
        ],
        'Niger': [
            r'Niger',
            r'République du Niger'
        ],
        'Sweden': [
            r'Sweden',
            r'Sverige'
        ],
        'Finland': [
            r'Finland'
        ],
        'Netherlands': [
            r'Netherlands',
            r'Nederland'
        ],
        'Singapore': [
            r'Singapore',
            r'Singapura'
        ],
        'Switzerland': [
            r'Switzerland',
            r'Schweiz',
            r'Suisse',
            r'Svizzera'
        ],
        'Denmark': [
            r'Denmark',
            r'Danmark'
        ],
        'Belgium': [
            r'Belgium',
            r'België',
            r'Belgique',
            r'Belgien'
        ],
        'Austria': [
            r'Austria',
            r'Österreich'
        ],
        'Poland': [
            r'Poland'
        ],
        'Portugal': [
            r'Portugal'
        ],
        'New Zealand': [
            r'New Zealand'
        ],
        'Malaysia': [
            r'Malaysia'
        ],
        'Ireland': [
            r'Ireland'
        ],
        'Turkey': [
            r'Turkey',
            r'Türkiye'
        ],
        'Iceland': [
            r'Iceland'
        ],
        'Philippines': [
            r'Philippines'
        ],
        'Greece': [
            r'Greece'
        ],
        'Czech': [
            r'Czech',
            r'Česká',
            r'Prague'
        ],
        'Estonia': [
            r'Estonia'
        ],
        'Cuba': [
            r'Cuba'
        ],
        'Argentina': [
            r'Argentina'
        ],
        'Bulgaria': [
            r'Bulgaria'
        ],
        'Yemen': [
            r'Yemen'
        ],
        'Ukraine': [
            r'Ukraine'
        ],
        'Kenya': [
            r'Kenya'
        ],
        'Belarus': [
            r'Belarus'
        ],
        'Saudi Arabia': [
            r'Saudi Arabia'
        ],
        'Egypt': [
            r'Egypt'
        ],
        'Chile': [
            r'Chile'
        ],
        'Slovakia': [
            r'Slovakia',
            r'Slovak'
        ],
        'Hungary': [
            r'Hungary'
        ],
        'Croatia': [
            r'Croatia'
        ],
        'Yugoslavia': [
            r'Yugoslavia'
        ],
        'Tunisia': [
            r'Tunisia'
        ],
        'Jamaica': [
            r'Jamaica'
        ],
        'Bangladesh': [
            r'Bangladesh'
        ],
        'Sri Lanka': [
            r'Sri Lanka'
        ],
        'UK': [
            r'[^\.]UK',
            r'U\.K\.',
            r'United Kingdom',
            r'Britain',
            r'U\. K',
            r'England',
            r'British'
        ],
        'Russia': [
            r'Russia',
            r'Россия',
            r'Russian',
            r'USSR',
            r'[\u0400-\u04FF]+'
        ],
        'Arab countries': [
            r'[\u0600-\u06FF]+'
        ],
    }
    
    result = ''
    for country, patterns in country_match.items():
        if country == 'China':
            if result in ['Taiwan', 'Hong Kong', 'Macau', 'Japan'] or re.search(r'\bChina Lake\b', input_string, re.IGNORECASE):
                continue
        if country == 'Israel':
            if re.search(r'\bBeth\.?Israel\b', input_string, re.IGNORECASE):
                continue
        if country == 'Denmark':
            if re.search(r'\bDenmark Hill\b', input_string, re.IGNORECASE):
                continue
        if country == 'Germany':
            if re.search(r'\bGerman Shepherd\b', input_string, re.IGNORECASE):
                continue
        if country == 'Ireland':
            if (re.search(r'\bNorthern Ireland\b', input_string, re.IGNORECASE) or
                re.search(r'\bN\. Ireland\b', input_string, re.IGNORECASE) or
                re.search(r'\bIreland and Jacobs\b', input_string, re.IGNORECASE)):
                continue
        if country == 'Mexico':
            if re.search(r'\bNew Mexico\b', input_string, re.IGNORECASE):
                continue
        if country == 'France':
            if (re.search(r'\bFrance Drive\b', input_string, re.IGNORECASE) or
                re.search(r'\bFrench Street\b', input_string, re.IGNORECASE)):
                continue
        if country == 'New Zealand':
            if re.search(r'\bAustralia[n]? and New Zealand\b', input_string, re.IGNORECASE):
                continue
        if country == 'UK':
            if (re.search(r'\bBritish Columbia\b', input_string, re.IGNORECASE) or
                re.search(r'\bNew England\b', input_string, re.IGNORECASE)):
                continue
        for pattern in patterns:
            if re.search(r'\b' + pattern + r'\b', input_string, re.IGNORECASE):
                if not result:
                    result = country
                else:
                    result = '!' + result + country
                break
    return result if result else None


def top_uni_company_match(input_string):
    import re

    uni_firm_match = {
        'Hong Kong': [
            r'The University of Hong Kong', r'The Chinese University of Hong Kong',
            r'CUHK', r'The Hong Kong University of Science and Technology',
            r'The Hong Kong Polytechnic University',
            r'City University of Hong Kong',
        ],
        'Taiwan': [
            r'National Taiwan University', r'NTU', r'Hon Hai Precision Industry',
            r'Taiwan Semiconductor', r'Pegatron', r'Quanta Computer', r'CPC',
            r'Compal Electronics', r'Wistron',
        ],
        'China': [
            r'Peking', r'Tsinghua', r'Zhejiang University', r'Fudan University',
            r'Shanghai Jiao Tong University', r'State Grid',
            r'China National Petroleum', r'Sinopec',
            r'China State Construction Engineering',
            r'Industrial & Commercial Bank of China', r'China Construction Bank',
            r'Agricultural Bank of China', r'Ping An Insurance',
            r'Sinochem Holdings', r'China Railway Engineering',
            r'China National Offshore Oil', r'China Railway Construction',
            r'China Baowu Steel', r'Bank of China', r'JD', r'China Life Insurance',
            r'China Mobile Communications', r'China Communications Construction',
            r'China Minmetals', r'Alibaba', r'Xiamen C&D', r'Shandong Energy',
            r'China Resources', r'China Energy Investment',
            r'China Southern Power Grid', r'SAIC Motor', r'China Post', r'COFCO',
            r'Xiamen ITG Holding', r'CITIC', r'PowerChina', r'Huawei',
            r'Sinopharm', r'COSCO Shipping', r'People\'s Insurance Co\. of China',
            r'Hengli', r'Amer International', r'China FAW',
            r'China Telecommunications', r'Zhejiang Rongsheng Holding',
            r'Wuchan Zhongda', r'XMXYG', r'China North Industries', r'Tencent',
            r'Aviation Industry Corp of China', r'Pacific Construction',
            r'Bank of Communications', r'Jinneng Holding',
            r'Guangzhou Automobile Industry', r'Aluminum Corp of China',
            r'Shaanxi Coal & Chemical Industry', r'Jiangxi Copper',
            r'Shandong Weiqiao Pioneering', r'China Vanke', r'China Merchants',
            r'China Merchants Bank', r'Dongfeng Motor', r'China Poly',
            r'China Pacific Insurance', r'Beijing Automotive',
            r'Greenland Holding', r'Country Garden Holdings', r'China Huaneng',
            r'BYD', r'Lenovo', r'Shenghong Holding', r'Industrial Bank',
            r'Zhejiang Geely Holding', r'HBIS', r'Zhejiang Hengyi',
            r'China National Building Material', r'China Electronics Technology',
            r'China Energy Engineering', r'Tsingshan Holding',
            r'Shanghai Pudong Development Bank', r'State Power Investment',
            r'China United Network Communications', r'Shaanxi Yanchang Petroleum',
            r'China State Shipbuilding', r'Midea Group', r'Sinamach', r'Ansteel',
            r'Jinchuan', r'Contemporary Amperex Technology',
            r'Zhejiang Communications Investment', r'Susun Construction',
            r'Jingye', r'China Huadian', r'China Minsheng Banking',
            r'China South Industries', r'Jiangsu Shagang',
            r'Shanghai Construction', r'China National Coal',
            r'Shanxi Coking Coal', r'Xiaomi', r'New Hope Holding',
            r'China Electronics', r'Zijin Mining', r'S\.F\. Holding',
            r'Guangzhou Municipal Construction',
        ],
        'USA': [
            r'MIT', r'M\.I\.T\.', r'Harvard', r'Stanford',
            r'University of California', r'UCB', r'University of Chicago',
            r'University of Pennsylvania', r'Cornell University',
            r'California Institute of Technology', r'Caltech', r'Yale University',
            r'Princeton University', r'Columbia University',
            r'Johns Hopkins University', r'University of California, Los Angeles',
            r'UCLA', r'University of Michigan\.?Ann Arbor', r'New York University',
            r'NYU', r'Northwestern University', r'Carnegie Mellon University',
            r'Duke University', r'University of Texas at Austin',
            r'University of California, San Diego', r'UCSD',
            r'University of Washington',
            r'University of Illinois at Urbana\.?Champaign', r'Brown University',
            r'Pennsylvania State University', r'Boston University',
            r'Georgia Institute of Technology', r'Purdue University',
            r'University of Wisconsin\.?Madison', r'Walmart', r'Amazon',
            r'Exxon Mobil', r'Apple', r'UnitedHealth', r'CVS Health',
            r'Berkshire Hathaway', r'Alphabet', r'McKesson', r'Chevron',
            r'Cencora', r'Costco Wholesale', r'Microsoft', r'Cardinal Health',
            r'Cigna', r'Marathon Petroleum', r'Phillips 66', r'Valero Energy',
            r'Ford Motor', r'Home Depot', r'General Motors', r'Elevance Health',
            r'JPMorgan Chase', r'Kroger', r'Centene', r'Verizon Communications',
            r'Walgreens Boots Alliance', r'Fannie Mae', r'Comcast', r'AT&T',
            r'Meta Platforms', r'Bank of America', r'Target', r'Dell Technologies',
            r'Archer Daniels Midland', r'Citigroup', r'UPS', r'Pfizer', r'Lowe\'s',
            r'Johnson & Johnson', r'Johnson and Johnson', r'FedEx', r'Humana',
            r'Energy Transfer', r'State Farm Insurance', r'Freddie Mac',
            r'PepsiCo', r'Wells Fargo', r'Walt Disney', r'ConocoPhillips',
            r'Tesla', r'Procter & Gamble', r'U\.S\. Postal Service', r'Albertsons',
            r'General Electric', r'MetLife', r'Goldman Sachs', r'Sysco',
            r'Bunge Global', r'RTX', r'Boeing', r'StoneX', r'Lockheed Martin',
            r'Morgan Stanley', r'Intel', r'HP', r'TD Synnex', r'IBM',
            r'HCA Healthcare', r'Prudential Financial', r'Caterpillar',
            r'Merck & Co\.', r'World Kinect', r'New York Life Insurance',
            r'Enterprise Products Partners', r'AbbVie', r'Plains GP Holdings',
            r'Dow', r'American International', r'American Express',
            r'Publix Super Markets', r'Charter Communications', r'Tyson Foods',
            r'Deere', r'Cisco Systems, Inc\.', r'Nationwide', r'Allstate',
            r'Delta Air Lines', r'Liberty Mutual Insurance', r'Progressive',
            r'American Airlines', r'Performance Food', r'PBF Energy', r'Nike',
            r'Best Buy', r'Bristol\.?Myers Squibb', r'United Airlines Holdings',
            r'Thermo Fisher Scientific', r'Qualcomm', r'Abbott Laboratories',
            r'Coca\.?Cola', r'Oracle', r'Nucor', r'TIAA',
            r'Massachusetts Mutual Life', r'General Dynamics',
            r'Capital One Financial', r'HF Sinclair', r'Dollar General',
            r'Arrow Electronics', r'Occidental Petroleum', r'Northwestern Mutual',
            r'Travelers Cos', r'Northrop Grumman', r'USAA',
            r'Honeywell International', r'US Foods Holding',
            r'Warner Bros Discovery', r'Lennar', r'D\.R\. Horton', r'Jabil',
            r'Cheniere Energy', r'Broadcom', r'Starbucks', r'Molina Healthcare',
            r'Uber Technologies', r'Philip Morris International', r'Netflix',
            r'NRG Energy', r'Mondelēz International', r'Danaher', r'Salesforce',
            r'Paramount Global', r'CarMax',
        ],
        'Mexico': [
            r'Universidad Nacional Autónoma de México', r'UNAM', r'Pemex',
            r'America Movil', r'Fomento Económico Mexicano',
        ],
        'Canada': [
            r'University of Toronto', r'McGill University',
            r'University of British Columbia', r'Brookfield',
            r'Alimentation Couche\-Tard', r'Royal Bank of Canada',
            r'Cenovus Energy', r'Toronto\-Dominion Bank', r'Suncor Energy',
            r'George Weston', r'Enbridge', r'Nutrien', r'Magna International',
            r'Power Corp\. of Canada', r'Bank of Nova Scotia', r'Bank of Montreal',
            r'Canadian Natural Resources',
        ],
        'UK': [
            r'University of Cambridge', r'University of Oxford',
            r'Imperial College London', r'UCL', r'The University of Edinburgh',
            r'The University of Manchester', r'King\'s College London',
            r'The London School of Economics and Political Science', r'LSE',
            r'University of Bristol', r'The University of Warwick',
            r'University of Leeds', r'University of Glasgow', r'Durham University',
            r'University of Southampton', r'University of Birmingham',
            r'University of St Andrews', r'University of Nottingham',
            r'Rio Tinto Group', r'Compass Group', r'AstraZeneca',
            r'Anglo American', r'Vodafone Group', r'British American Tobacco',
            r'Shell', r'BP plc', r'HSBC Holdings', r'Tesco', r'Unilever',
            r'Barclays', r'GSK', r'J\. Sainsbury', r'Linde',
        ],
        'Australia': [
            r'The University of Melbourne', r'The University of New South Wales',
            r'UNSW Sydney', r'The University of Sydney',
            r'Australian National University', r'ANU', r'Monash University',
            r'The University of Queensland',
            r'The University of Western Australia', r'The University of Adelaide',
            r'University of Technology Sydney', r'BHP Group', r'Woolworths',
        ],
        'New Zealand': [
            r'The University of Auckland',
        ],
        'Singapore': [
            r'National University of Singapore', r'NUS',
            r'Nanyang Technological University', r'NTU Singapore',
            r'Trafigura Group', r'Wilmar International', r'Olam Group',
        ],
        'Switzerland': [
            r'ETH Zurich', r'EPFL', r'École polytechnique fédérale de Lausanne',
            r'University of Zurich', r'Glencore', r'Nestlé', r'Roche Group',
            r'Novartis', r'Swiss Re', r'Chubb', r'UBS Group',
            r'Zurich Insurance Group', r'Kuehne \+ Nagel International',
            r'Coop Group', r'Migros Group',
        ],
        'Germany': [
            r'Technical University of Munich',
            r'Ludwig\-Maximilians\-Universität München', r'Universität Heidelberg',
            r'Freie Universitaet Berlin', r'Volkswagen', r'Uniper',
            r'Mercedes\-Benz Group', r'BMW', r'Allianz', r'Deutsche Telekom',
            r'DHL Group', r'BASF', r'Siemens', r'Munich Re Group',
            r'Deutsche Bahn', r'Energie Baden\-Württemberg', r'Talanx',
            r'Daimler Truck Holding', r'Bayer', r'Edeka Zentrale',
            r'ZF Friedrichshafen', r'ThyssenKrupp', r'Fresenius', r'Deutsche Bank',
            r'Continental', r'Phoenix Pharma', r'Hapag\-Lloyd', r'Lufthansa Group',
            r'SAP', r'Siemens Energy', r'Merck KGaA',
        ],
        'Japan': [
            r'The University of Tokyo', r'Kyoto University', r'Osaka University',
            r'Tokyo Institute of Technology', r'Tokyo Tech', r'Toyota Motor',
            r'Mitsubishi', r'Honda Motor', r'Mitsui', r'Itochu',
            r'NTT \(Nippon Telegraph & Telephone\)', r'ENEOS Holdings',
            r'Seven & I Holdings', r'Sony', r'Japan Post Holdings',
        ],
        'Brazil': [
            r'Universidade de São Paulo', r'Petrobras', r'JBS',
            r'Itaú Unibanco Holding', r'Banco do Brasil', r'Banco Bradesco',
            r'Raízen', r'Vale', r'Caixa Econômica Federal', r'Vibra Energia',
        ],
        'Russia': [
            r'Lomonosov Moscow State University', r'Gazprom', r'Sberbank',
            r'Magnit', r'X5 Retail Group',
        ],
        'Ireland': [
            r'Trinity College Dublin', r'The University of Dublin', r'Accenture',
            r'CRH', r'Medtronic',
        ],
        'Netherlands': [
            r'Delft University of Technology', r'University of Amsterdam',
            r'Stellantis', r'Royal Ahold Delhaize', r'Louis Dreyfus',
            r'LyondellBasell Industries', r'ING Group', r'Ingka Group',
            r'EXOR Group', r'GasTerra',
        ],
        'Malaysia': [
            r'Universiti Malaya', r'Petronas',
        ],
        'France': [
            r'Airbus', r'Université PSL', r'Institut Polytechnique de Paris',
            r'Sorbonne University', r'Université Paris\.?Saclay', r'TotalEnergies',
            r'Electricité de France', r'Engie', r'Carrefour', r'BNP Paribas',
            r'Crédit Agricole', r'Christian Dior', r'Vinci', r'Société Générale',
            r'Saint\-Gobain', r'Renault', r'Sanofi', r'Groupe BPCE', r'Bouygues',
            r'Orange', r'Veolia Environnement', r'SNCF Group', r'L\'Oréal',
            r'Schneider Electric', r'Finatis', r'ELO Group', r'Air Liquide',
            r'La Poste',
        ],
        'Argentina': [
            r'Universidad de Buenos Aires', r'UBA',
        ],
        'South Korea': [
            r'Seoul National University', r'KAIST',
            r'Korea Advanced Institute of Science & Technology',
            r'Korea Advanced Institute of Science and Technology',
            r'Yonsei University', r'Korea University',
            r'Pohang University of Science And Technology', r'POSTECH',
            r'SK Group', r'Samsung C&T', r'HD Hyundai', r'KB Financial Group',
            r'Samsung Electronics', r'GS Caltex', r'SK Hynix', r'Hyundai Mobis',
            r'Kia', r'POSCO Holdings', r'Korea Gas', r'LG Chem',
            r'Korea Electric Power', r'Samsung Life Insurance', r'Hanwha',
            r'CJ Corp', r'Hyundai Motor', r'LG Electronics',
        ],
        'Sweden': [
            r'KTH Royal Institute of Technology', r'Lund University', r'Volvo',
        ],
        'Austria': [
            r'OMV Group',
        ],
        'Italy': [
            r'Enel', r'ENI', r'Assicurazioni Generali', r'Intesa Sanpaolo',
        ],
        'Colombia': [
            r'Ecopetrol',
        ],
        'Norway': [
            r'Equinor',
        ],
        'Thailand': [
            r'PTT',
        ],
        'Turkey': [
            r'Koç Holding',
        ],
        'Poland': [
            r'Orlen',
        ],
        'Indonesia': [
            r'Pertamina',
        ],
        'India': [
            r'Reliance Industries', r'Indian Oil',
            r'Life Insurance Corp\. of India', r'Oil & Natural Gas',
            r'Bharat Petroleum', r'State Bank of India', r'Tata Motors',
            r'Rajesh Exports',
        ],
        'Denmark': [
            r'Maersk', r'Energi Danmark', r'DSV',
        ],
        'Luxembourg': [
            r'ArcelorMittal',
        ],
        'Saudi Arabia': [
            r'Saudi Aramco',
        ],
        'Spain': [
            r'Banco Santander', r'Repsol', r'Iberdrola',
            r'Banco Bilbao Vizcaya Argentaria', r'Telefónica', r'Naturgy Energy',
            r'ACS', r'Inditex',
        ],
        'Belgium': [
            r'KU Leuven', r'Anheuser\-Busch InBev',
        ],
    }

    result = ''
    for country, patterns in uni_firm_match.items():
        for pattern in patterns:
            if re.search(r'\b' + pattern + r'\b', input_string, re.IGNORECASE):
                if not result:
                    result = country
                else:
                    result = '!' + result + country
                break
    return result if result else None


def city_state_match(input_string):
    import re

    US_state = [
        r'(AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY)\s*\d{5}',
        r',\s*(AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY)'
    ]

    city_state_match = {
        'USA': [
            r'California', r'Princeton', r'Chicago', r'Yale', r'Columbia',
            r'Pennsylvania', r'Cornell', r'Berkeley', r'Johns Hopkins', r'Duke',
            r'Michigan', r'Virginia', r'San Diego', r'Chapel Hill', r'New York',
            r'Los Angeles', r'San Francisco', r'Miami', r'Rush University',
            r'Brown', r'Emory', r'Rice', r'Georgetown University',
            r'Vanderbilt University',
            r'University of Illinois at Urbana.?Champaign',
            r'University of Rochester', r'Dartmouth College', r'Tufts University',
            r'University of Virginia', r'Case Western Reserve University',
            r'Northeastern University', r'University at Buffalo SUNY',
            r'University of Minnesota Twin Cities', r'Syracuse University',
            r'Lehigh University', r'Austin', r'Notre Dame', r'Ohio State',
            r'Purdue', r'Case Western Reserve', r'St\. Louis',
            r'Baylor college of Medicine', r'Scripps Research Institute',
            r'Fred Hutchinson', r'Las Vegas', r'Washington', r'Seattle', r'Boston',
            r'New Orleans', r'Houston', r'Philadelphia', r'Dallas', r'Atlanta',
            r'National Institutes of Health', r'Carnegie Mellon', r'Pittsburgh',
            r'Yeshiva', r'Thomas Jefferson', r'Cleveland Clinic',
            r'J\. Craig Venter Institute', r'VA Medical Center',
            r'Dana.?Farber Cancer Institute', r'Alabama', r'Alaska', r'Arizona',
            r'Arkansas', r'Colorado', r'Salk Institute for Biological Studies',
            r'Wake Forest', r'Stony Brook', r'Connecticut', r'Delaware',
            r'Florida', r'Georgia', r'Hawaii', r'Idaho', r'Wayne State',
            r'Howard Hughes Medical Institute', r'Illinois', r'Indiana', r'Iowa',
            r'Kansas', r'Kentucky', r'Louisiana',
            r'Centers for Disease Control and Prevention', r'Creighton University',
            r'Maine', r'Maryland', r'Massachusetts', r'Minnesota',
            r'Rockefeller University', r'Drexel University', r'Tulane',
            r'Cincinnati', r'Baltimore', r'Mississippi', r'Missouri', r'Montana',
            r'Nebraska', r'Nevada', r'Cold.?Spring.?Harbor Laboratory',
            r'Cold, Spring Harbor', r'Oak Ridge National Laboratory', r'Rutgers',
            r'Research Triangle Park', r'Los Alamos national Laboratory',
            r'Lawrence livermore National Laboratory', r'New Hampshire',
            r'New Jersey', r'New Mexico', r'North Carolina', r'North Dakota',
            r'Ohio', r'Oklahoma', r'Oregon', r'Rockville', r'Auburn University',
            r'Rhode Island', r'South Carolina', r'South Dakota', r'Tennessee',
            r'Texas', r'Utah', r'Vermont', r'United States', r'West Virginia',
            r'Wisconsin', r'Wyoming', r'Lucent', r'Microsoft Research',
            r'Memorial.?Sloan.?Kettering', r'J\.Craig Venter Institute',
            r'SUNY Upstate Medical University', r'Portland State', r'Oakland',
            r'Wright State', r'Icahn School of Medicine at Mount Sinai',
            r'Whitehead Institute for BioMedical Research',
            r'Palo Alto Research Center', r'Argonne National Laboratory', r'NIH',
            r'Temple University', r'University Of Louisville', r'SUNY.?Buffalo',
            r'SUNY.?Binghamton', r'Bell Laboratories', r'Bell Lab', r'Rensselaer',
            r'U\. S\. Dept\. of Agriculture',
            r'U\.S\. Food and Drug Administration',
            r'Laboratory of Tumor Immunology and Biology',
            r'Scripps Clinic and Research Foundation',
            r'Department of Veterans Affairs',
            r'Sanford Burnham Prebys Medical Discovery Institute',
            r'St\. Jude Children Research Hospital',
            r'Roswell Park Cancer Institute', r'Bloomberg School of Public Health',
            r'Case Comprehensive Cancer Center',
            r'National Institute of Standards and Technology', r'Emeryville',
            r'Walter Reed Army Institute of Research',
            r'Pacific Northwest National Laboratory',
            r'National Renewable energy laboratory',
            r'Cedars-Sinai Medical Center', r'MedImmune', r'Wistar',
            r'City of Hope', r'Bethesda',
            r'Carl R\. Woese Institute for Genomic Biology',
            r'Lippincott Williams & Wilkins', r'National Naval Medical Center',
            r'Uniformed Services University of the Health Sciences',
            r'National Institute of Diabetes and Digestive and Kidney Diseases',
            r'North Shore-Long Island Jewish Health System',
            r'Penn State Cancer Institute', r'Developmental Therapeutics Program',
            r'Institute for Systems Biology', r'Sandia National Laboratories',
            r'Pharmacology - Corey Lab', r'Naval Research Laboratory',
            r'Samuel and Jean Frankel Cardiovascular Center',
            r'Brigham and women\'s Hospital',
            r'Southwest Foundation for Biomedical Research',
            r'Brandeis University', r'Saint Louis University',
            r'La Jolla Inst\. for Allergy and Immunology', r'Brigham.?Young',
            r'National Jewish Medical and Research Center',
            r'National Cancer Institute', r'Brookhaven National Laboratory',
            r'Vollum Institute', r'George Mason University',
            r'University of Toledo', r'Billerica', r'Jackson Laboratory',
            r'Dow Chemical', r'Albany Medical College',
            r'Cell Genesys Inc\., Foster City', r'American College of Cardiology',
            r'Eastman Kodak', r'Medarex Inc', r'Affymetrix, Santa Clara',
            r'Augusta University', r'Network Appliance Corporation',
            r'Shriners Hospitals for Children', r'Clemson University',
            r'Lilly Research Laboratories, Lilly Corporate Center',
            r'Banner Sun Health Research Institute', r'Kennedy Krieger Institute',
            r'NASA', r'Integrated Surgical Systems', r'IRIS, Chiron Vaccines',
            r'Medtronic', r'University of Tulsa', r'Gene Therapy Center',
            r'Raytheon', r'American Cancer Society',
            r'Charles R\. Drew University of Medicine and Science',
            r'Counterpane Systems', r'Southwest Oncology Group Statistical Center',
            r'LSU Pennington Biomedical Research Center', r'LDS Hospital',
            r'Calgene Inc\., Davis', r'Health Sciences Research',
            r'Translational Genomics Research Institute',
            r'Bowling Green State Univ', r'Bachem Bioscience Inc\.',
            r'Fibrogen Inc', r'Dade-Behring Corporation',
            r'Renaissance Technologies', r'Tilera', r'Hofstra University',
            r'Department of Information and Computer Science',
            r'Quantum Dot Corporation, Hayward', r'Immunicon Corporation',
            r'Incyte', r'Wellman Center for Photomedicine',
            r'Children\'s National Medical Center\.', r'Sangamo BioSciences',
            r'David Sarnoff Research Center',
            r'Baylor Research Foundation, Southern Methodist University and the Southwest Foundation for Biomedical Research',
            r'WesternGeco', r'MERL', r'Angeles Clinic and Research Institute',
            r'Geisinger Medical Center', r'Parker Hughes Institute',
            r'Signal Corps Engineering Laboratories, Fort Monmouth, N\.J\.',
            r'Partners Healthcare;', r'International Computer Science Institute',
            r'Digital Equipment Corp\.', r'Graduate School of Biomedical Sciences',
            r'Illumina;', r'St\. Joseph\'s Hospital and Medical Center',
            r'Hennepin County Medical Center',
            r'Lineberger Comprehensive Cancer Center', r'Carolinas Medical Center',
            r'Beckman Coulter', r'Fordham University',
            r'Bowie State University, Bowie MD',
            r'Legacy Clinical Research and Technology Center',
            r'UT Southwestern Medical School', r'Integrated Genetics, Framingham',
            r'Halliburton Energy Services Group', r'The EMMES Corporation',
            r'Lovelace Respiratory Research Institute',
            r'Wadsworth Center for Laboratories and Research',
            r'National Institute of Health', r'Old Dominion University',
            r'The Institute for Genomic Research', r'Loma Linda University',
            r'Children\'s Memorial Hospital', r'Clinical Cancer Prevention Inc',
            r'Plexxikon Inc', r'GLOBAL FOUNDRIES INC',
            r'Medicine - Veteran\'s Administration Medical Center',
            r'Marshfield Clinic', r'VAN ANDEL RESEARCH INSTITUTE',
            r'SCRIPPS Clinic', r'Genzyme Corporation, Framingham',
            r'Lexicon Genetics Incorporated',
            r'American Society of Clinical Oncology', r'Cell Genesys, Foster City',
            r'Union Carbide Corporation, Tarrytown Technical Center',
            r'Dow AgroSciences, LLC, Huxley', r'HP Labs',
            r'Lilly Research Laboratories', r'John Wiley and Sons',
            r'The Nancy B\. and Jake L\. Hamon Center for Therapeutic Oncology Research',
            r'St Jude Children\’s Research Hospital', r'Baker Hughes', r'Amherst',
            r'Children\'s Hospital Columbus', r'Immunex Corporation',
            r'Pixar Animation Studios',
            r'Hudson Institute - Department of Molecular and Translational Science',
            r'Biomedical Photonic Imaging Research Laboratories, The Upjohn Company',
            r'Millennium Pharmaceuticals', r'Pacific Northwest Research Institute',
            r'SUNY.?Albany', r'Scripps.?Research',
            r'Buck institute for age research',
            r'American Sleep Disorders Association', r'Naval Postgraduate School',
            r'Robert Wood Johnson Medical School', r'O\'Reilly & Associates',
            r'Armed Forces Institute of Pathology', r'University of Memphis',
            r'Association for Computing Machinery',
            r'Computer Graphics Project, Lucasfilm Ltd\.', r'University of Akron',
            r'National Institute of Environmental Health Sciences',
            r'Morgridge Institute for Research',
            r'SUNY Downstate Health Sciences University',
            r'Amer\. Assoc\. Electrodiagnostic Med\.', r'UIUC', r'Rochester, N\.Y',
            r'Research Triangle Institute',
            r'Randall Division of Cell & Molecular Biophysics', r'USC',
            r'Albert Einstein College of Medicine',
            r'Lawrence Livermore Laboratory',
            r'Department of Cell Biology, Upjohn Laboratories, Kalamazoo',
            r'John Wayne Cancer Institute', r'Marquette University',
            r'Howard University:', r'RTI International',
            r'Worcester Polytechnic Institute',
            r'Beth Israel Deaconess Medical Center', r'New England BioLabs',
            r'University of Denver',
            r'Penn State Clinical and Translational Science Institute',
            r'Sunnyvale', r'Protein Sciences', r'American Medical Association',
            r'CELERA', r'Butler Hospital',
            r'Stowers Institute for Medical Research',
            r'National Institute of Mental Health', r'Framingham',
            r'Kent State University', r'Conocophillips',
            r'Nathan S\. Kline Institute for Psychiatric Research', r'Nashville',
            r'National Bureau of Economic Research', r'NBER',
            r'Departments of Surgery and Division of Cardiology',
            r'INOVA Fairfax Hospital', r'GENENCOR INTERNATIONAL INCORPORATED',
            r'Hamon Center Therapeutic Oncology - Minna Lab',
            r'Lantheus Medical Imaging', r'School of Nursing',
            r'University at Buffalo', r'Penn State Heart and Vascular Institute',
            r'3M Drug Delivery Systems Division', r'University of Hawaii at Manoa',
            r'Cel-Sci Corporation', r'Roswell Park Memorial Institute, Buffalo',
            r'Bothell', r'College Of William and Mary',
            r'Hamon Center For Therapeutic Oncology',
            r'Institute of Electrical and Electronics Engineers',
            r'Mount Sinai School of medicine', r'Isis Pharmaceuticals',
            r'SUNY--Albany', r'Monsanto Company', r'BBN Technologies',
            r'Beckman Institute for Advanced Science and Technology',
            r'Vical Incorporated', r'PARC', r'Wright-Patterson AFB',
            r'Veterans Affairs Medical Center', r'Ionis Pharmaceuticals',
            r'Enzon INC', r'Waksman Institute of Microbiology',
            r'Northern Regional Research Laboratory, Peoria',
            r'American Association for Cancer Research',
            r'St Elizabeth\'s Medical Center',
            r'Bell Telephone Laboratories Murray Hill N\. J\.',
            r'Union Memorial Hospital', r'UC Riverside,',
            r'Rainbow Babies and Children\'s Hosp\.',
            r'Genomic Health Incorporated, Redwood City', r'Reed College',
            r'Knight Cancer Institute', r'National Semiconductor Corporation',
            r'East Carolina University', r'Kaiser-Permanente',
            r'Advanced Micro Devices', r'William Beaumont Hospital',
            r'Eppley Institute for Cancer Research', r'AT&T Labs',
            r'Chemistry (Twin Cities)', r'Genelabs Incorporated, Redwood City',
            r'Rosalind Franklin University of Medicine & Science',
            r'Salk Institute for Biological Studies, Gene Express Lab',
            r'Scott and White Memorial Hospital', r'Santa Fe Institute',
            r'Scottsdale Healthcare',
            r'Roche Institue of Molecular Biology, Nutley',
            r'Gilead Sciences, Foster City', r'Brooke Army Medical Center',
            r'Lexicon Pharmaceuticals', r'Los Alamos National Lab',
            r'DePaul University', r'American Diabetes Association',
            r'University of Minnesota', r'Allegheny General Hospital',
            r'Genelabs Incorporated', r'Partners AIDS Research Center',
            r'Cardiovascular Devices', r'Medical Microbiology and Immunology',
            r'Gladstone Institutes',
            r'U\. S Army Research Institute of Environmental Medicine',
            r'U\. S\. Environmental Protection Agency',
            r'Huntington Medical Research Institutes', r'Xilinx Inc\., San Jose',
            r'Women and Children\'s Hospital of Buffalo', r'Cleveland',
            r'Baylor University', r'SUNY Downstate Medical Center',
            r'Vanderbilt Ingram Cancer Center',
            r'Penn State Neuroscience Institute', r'Agios Pharmaceuticals\.',
            r'Rand Corporation', r'San Jose State',
            r'Christiana Care Health system', r'American Academy of Neurology',
            r'UC Santa Cruz', r'Carnegie-Mellon', r'Affymax Research Institute',
            r'UnitedHealth Group', r'AmerisourceBergen', r'Yahoo', r'Motorola',
            r'Google', r'ExxonMobil', r'Costco', r'DuPont', r'Osiris Therapeutics',
            r'hewlett packard', r'Hewlett-Packard', r'Bank of America Corp',
            r'Honeywell', r'Anthem', r'DuPont de Nemours', r'nVidia', r'CISCO',
            r'InterSense', r'United Parcel Service', r'Lowe\'s', r'Exxon',
            r'Adobe', r'Corning', r'Raytheon Company', r'SARNOFF CORP',
            r'Splunk Inc', r'AT&amp;T Labs', r'Group Health Cooperative',
            r'Mayo Clinic', r'Mayo College of Medicine', r'Merck', r'Eli Lilly',
            r'Schlumberger', r'Henry Ford Health System', r'Xerox',
            r'Sun Microsystems', r'Amgen', r'Geron Corp', r'SRI-International',
            r'Telcordia Technologies', r'Halliburton', r'Amoco Production',
            r'Genentech', r'Enchira Biotechnology Corporation, The Woodlands',
            r'Altor BioScience', r'SAIC.?Frederick', r'ZymoGenetics',
            r'Qualcomm Inc', r'CRAY INC', r'Luminex Corp', r'NetApp',
            r'SPECTROLab', r'AmCell Corp', r'Mentor Graphics',
            r'Applied Biosystems', r'Ashland Chemical', r'Facebook',
            r'Encysive Pharmaceuticals',
        ],
        'Puerto Rico': [
            r'University of Puerto Rico',
        ],
        'United Kingdom': [
            r'Medical Research Council, Toxicology Unit',
            r'Queen\’s University , Belfast',
            r'Department of Biology, University of Essex', r'Keele University',
            r'Babraham Institute',
            r'Cancer Research UK Clinical Trials Unit, CR UK Institute for Cancer Studies, Clinical Research Block',
            r'Wolfson Centre for Age-related Diseases', r'University of Aberdeen',
        ],
        'Brazil': [
            r'Hospital Procardiaco', r'Universidade Estadual de Campinas',
            r'São Paulo', r'do Rio de Janeiro',
            r'DCM - Departamento de Ciência dos Materiais',
            r'Universidade Federal do Rio Grande do Sul', r'Fundação Oswaldo Cruz',
            r'UFRGS', r'Instituto Dante Pazzanese de Cardiologia',
            r'Universidade Federal de Minas Gerais',
            r'Universidade Federal do Rio de Janeiro',
            r'State University of Campinas',
            r'National Institute for Space Research',
        ],
        'Germany': [
            r'University of Potsdam', r'German', r'Universität', r'GmbH',
            r'München', r'Heidelberg', r'Berlin Humboldt', r'Berlin Freie',
            r'Aachen RWTH', r'Freiburg', r'Göttingen', r'Jena', r'Marburg',
            r'Tübingen', r'Hamburg', r'Karlsruhe', r'Max.?Planck', r'Bonn',
            r'Stuttgart', r'Mannheim', r'Frankfurt', r'Munich', r'Humboldt',
            r'Berlin', r'RWTH Aachen', r'University of Gottingen', r'Wurzburg',
            r'Erlangen', r'Ulm University', r'Max.?Planck.?Institute', r'Köln',
            r'Saarland', r'Heinrich Heine University Düsseldorf',
            r'University of Cologne', r'University of Münster',
            r'Universitatsklinikum des Saarlandes', r'University of Regensburg',
            r'Justus-Liebig University',
            r'Max- Planck-Institute of Microstructure Physics',
            r'University of Konstanz\.', r'University of Leipzig',
            r'University of Lübeck', r'University of Würzburg',
            r'Institut für Organische Chemie der Technischen Hochschule, Hannover',
            r'University of Rostock', r'University of Göettingen',
            r'Jülich Research Centre', r'Deutsches Krebsforschungszentrum',
            r'University of Ulm', r'Osnabrück',
            r'Martin-Luther University, Halle-Wittenberg',
            r'Dresden University of Technology', r'University of Mainz',
            r'Ruhr-Universität Bochum',
            r'Cologne Excellence Cluster on Cellular Stress Responses in Aging-Associated Diseases, and Department of Molecular Oncology',
            r'University of Kiel', r'European Molecular Biology Laboratory',
            r'Fraunhofer Society', r'HANNOVER MEDICAL SCHOOL',
            r'University of Duisburg-Essen', r'University of Kaiserslautern',
            r'Ruhr-Univ\. Bochum', r'University of Bremen',
            r'Charité University Hospital', r'University Hospital of Cologne',
            r'Aachen University of Technology', r'Leipzig University',
            r'Rostock Uni', r'Friedrich-Alexander-University', r'Daimler',
            r'Mercedes-Benz',
        ],
        'Japan': [
            r'Eisai Co, Ltd', r'Kyoto', r'Osaka', r'Tohoku', r'Nagoya',
            r'Hokkaido', r'Kyushu', r'Keio', r'Waseda', r'Tokyo', r'Hitotsubashi',
            r'Chiba', r'Hiroshima', r'Kumamoto', r'Kobe', r'Sophia',
            r'Ritsumeikan', r'Yokohama', r'Nagasaki', r'Toshiba',
            r'University of Tsukuba', r'Ibaraki', r'Okayama University',
            r'Fujita Health University', r'kitasato',
            r'Nagaoka University of Technology', r'Niigata',
            r'Juntendo University', r'Gifu University', r'RIKEN',
            r'Kansai Research Institute', r'Institute of Microbial Chemistry',
            r'Japanese',
            r'National Institute of Advanced Industrial Science and Technology',
            r'Showa University', r'Tsukuba', r'Kanazawa', r'Kagawa',
            r'Renesas Technology Corp', r'Nara Institute of Science & Technology',
            r'Gunma univ', r'Tottori University', r'Shionogi Research Laboratory',
            r'Mie University', r'Nichia Chemical Industries', r'Kurume-university',
            r'Yamaguchi', r'Fujitsu',
            r'National Agriculture and Food Research Organization', r'TOKAI Univ',
            r'Tokushima University', r'University of Yamanashi',
            r'saga University', r'Saitama Cancer Center',
            r'National Cerebral and Cardiovascular Center Research Institute',
            r'Fukuoka University Hospital',
            r'National Defense Medical College Tokorozawa',
            r'Nippon Medical School', r'Saitama', r'Hyogo',
            r'Nara Institute of Science and Technology',
            r'National Research Institute for Metals',
            r'Meiji Pharmaceutical University',
            r'Shionogi Research Laboratory, Shionogi and Co\., Ltd\.',
            r'Department of Molecular Biology,',
            r'Department of Bioresources Science, Kochi University',
            r'Kochi University\.', r'Sagami Chemical Research Center',
            r'Faculty of Environment and Information Studies',
            r'University of Toyama', r'Josai University', r'Kishiwada',
            r'Kindai University', r'University of Ryukyus', r'Fukushima',
            r'Chitose Institute of Science and Technology', r'Toyohashi',
            r'Miyazaki', r'Kochi University', r'Istituto Scienze Neurologiche',
            r'National Center of Neurology and Psychiatry Kodaira',
            r'Japan Atomic Energy Agency', r'Ehime University',
            r'Japan Adv\. Inst\. of Science and Tech\.', r'Shionogi & Co\., Ltd\.',
            r'Pharmaceutical Science & Technology, Eisai Product Creation Systems',
            r'The Institute of Physical and Chemical Research',
            r'National Institute of Advanced Industrial Sci\. and Tech\. \(AIST\)',
            r'Kawasaki Medical School', r'Renesas Technol\. Cooperation, Itami',
            r'MOCHIDA PHARMACEUTICAL', r'Tohoku University',
            r'First Department of Internal Medicine Mie University School of Medicine',
            r'Akita', r'Kurume University School of Medicine', r'Nara Medical',
            r'Sagamihara', r'Toho University', r'Gifu Pharmaceutical University',
            r'National Institute of Technology and Evaluation',
            r'Shinshu University', r'Yamagata', r'Shionogi Research Laboratories',
            r'National Institute of Infectious Diseases',
            r'National Cancer Center Hospital', r'Asahikawa Medical University',
            r'Aichi Cancer Center', r'Kagoshima',
            r'National Cerebral and Cardiovascular Center',
            r'National Research Institute of Brewing',
            r'New Industry Creation Hatchery Center',
            r'Japan Science and Technology Agency', r'Toyota', r'SoftBank',
            r'Nissan Motor', r'Hitachi', r'Sumitomo Mitsui Financial',
            r'Honda R&D', r'Bridgestone', r'Canon', r'Mitsubishi Electric',
            r'Semicond.?Energy Lab', r'Nippon Telegraph & Telephone',
            r'Kyowa Hakko', r'Suzuki Motor', r'Nippon Steel', r'Asahi-Kasei',
            r'Nec Corporation', r'Sharp', r'Panasonic', r'Nikon',
            r'Fujisawa Pharmaceutical', r'Fuji ImmunoPharmaceuticals Corp',
            r'Yoshitomi Pharmaceutical Industries', r'NGK Insulators',
            r'Kirin Brewery', r'Research Center Taisho Pharmaceutical',
        ],
        'France': [
            r'Ecole Normale Superieure', r'Laboratoire Hubert Curien',
            r'French Institute for Research in Computer Science and Automation',
            r'Paris', r'Sorbonne', r'Paris.?Saclay', r'Panthéon.?Sorbonne',
            r'Lyon', r'Jean Moulin', r'Toulouse', r'Marseille', r'Bordeaux',
            r'Lille', r'Strasbourg', r'Grenoble', r'Montpellier', r'Nantes',
            r'Rennes', r'Université Paris.?Saclay', r'CNRS',
            r'Pierre.?and.?Marie.?Curie University', r'institut Gustave Roussy',
            r'Institut National de la Sante et de la Recherche Medicale',
            r'International Agency for Research on Cancer',
            r'Centre de biophysique moléculaire',
            r'Laboratoire d\'optique appliquée',
            r'Franche-Comté Électronique Mécanique',
            r'Pierre Fabre Recherche et Developpement',
            r'Institut National de la Recherche Agronomique',
            r'École Normale Supérieure', r'Service Hospitalier Frédéric Joliot',
            r'CEA-Léti-MINATEC',
            r'Laboratoire de Bioélectrochimie et Analyse du Milieu',
            r'Institut National de la Santé et de la Recherche Médicale',
            r'Institut Pasteur', r'Génétique des maladies multifactorielles',
            r'Institut Francais du Petrole', r'Hôpital Beaujon',
            r'CHU Bretonneau, Tours', r'PSL research University',
            r'Institut National de la Santé et de la Recherche Médicate',
            r'Transgene', r'Université Pierre', r'Récepteurs et Cognition',
            r'Clinique Pasteur', r'Université de Franche-Comté',
            r'Département de neurologie', r'INRIA Rocquencourt',
            r'Pharmacochimie moléculaire et structurale',
            r'Université Claude Bernard', r'Hôpital Saint-Antoine', r'AXA',
            r'L\'Oréal', r'Airbus Group', r'Dior', r'Capgemini', r'Saint.?Gobain',
            r'Danone', r'Peugeot', r'Michelin', r'Vivendi', r'Thales',
            r'EssilorLuxottica', r'STMicroelectronics', r'Hermès',
            r'Publicis Groupe', r'Inserm', r'Institut Curie',
        ],
        'Denmark': [
            r'Novo Nordisk Biotech', r'OUH Svendborg Hospital',
            r'Risø National Laboratory for Sustainable Energy', r'Denmark',
            r'Copenhagen', r'København', r'Santaris Pharma AS',
            r'Syddansk Universitet', r'Aalborg university', r'Exiqon A/S',
            r'Novo Nordisk A/S',
        ],
        'China': [
            r'Fudan', r'Shanghai', r'Nankai', r'Tianjin',
            r'Southern medical university', r'USTC', r'Nanjing', r'Wuhan',
            r'Sun.?Yat.?sen', r'Harbin', r'Southeast University', r'Huazhong',
            r'Sun Yat-sen University', r'Xi\'an', r'Jiaotong', r'Tongji',
            r'Beijing', r'Xiamen', r'Central South', r'Beihang',
            r'Northwest A&F University', r'Renmin',
            r'Northeastern University (China)', r'Northwest University (China)',
            r'Soochow University', r'Anhui', r'Fujian', r'Gansu', r'Guangdong',
            r'Guizhou', r'Hainan', r'Shandong', r'Chongqing', r'Zhengzhou',
            r'Hebei', r'Heilongjiang', r'Henan', r'Hubei', r'Hunan', r'Jiangsu',
            r'Jiangxi', r'Jilin', r'Liaoning', r'Qinghai', r'Shaanxi', r'Shanxi',
            r'Sichuan', r'Yunnan', r'Zhejiang', r'Guangxi', r'Guangzhou',
            r'Shenzhen', r'Chengdu', r'Hangzhou', r'Shenyang', r'Qingdao',
            r'Dalian', r'Nanchang', r'Hefei', r'Changsha', r'Kunming', r'Urumqi',
            r'Lanzhou', r'Chinese Academy of sciences',
            r'Chinese academy of medical sciences',
            r'China Agricultural University', r'Capital Medical University',
            r'Nantong', r'Shantou', r'National University of Defense Technology',
            r'Jiangnan University', r'Northwestern Polytechnical University',
            r'China Medical University',
            r'Chinese Center for Disease Control and Prevention',
            r'University of Science and Technology',
            r'CAS - Institute of Microbiology',
            r'Second Military Medical University',
            r'Third Military Medical University',
            r'Fourth Military Medical University',
            r'CAS - Institute of Biophysics', r'PetroChina', r'Taiyuan',
            r'Changchun', r'Yan-Tai', r'Yantai', r'Zhongshan', r'Suzhou',
            r'Yangzhou', r'ChinaUniversityofPetroleum', r'The Chinacare Group',
            r'Northeast Normal University', r'Yinchuan', r'Sinopharm Group',
            r'Baidu', r'Haier', r'ByteDance', r'Central-South University',
            r'Huawei', r'Ping An Insurance', r'Alibaba', r'Dongfeng Motor',
            r'JD', r'Xiaomi', r'Tencent',
            r'Jinan', r'Wuxi', r'Ningbo', r'Dongguan', r'Luoyang', r'Xining',
            r'BYD', r'SAIC Motor', r'Sinopec', r'China Mobile', r'Lenovo', r'NetEase'
        ],
        'Canada': [
            r'British Columbia', r'Toronto', r'Vancouver', r'Montreal',
            r'Montréal', r'Calgary', r'Ottawa', r'Edmonton', r'Winnipeg',
            r'Quebec', r'Québec', r'Hamilton', r'Kitchener', r'Halifax',
            r'Saskatoon', r'Colombie-Britannique', r'Alberta', r'Ontario',
            r'Nova Scotia', r'Nouvelle-Écosse', r'Manitoba',
            r'McMaster University', r'University of Waterloo',
            r'Queen\'s University', r'Université Laval', r'Queen\’s University',
            r'University of Alberta', r'University of Montreal',
            r'Western University', r'University of Calgary',
            r'Simon Fraser University', r'Dalhousie University',
            r'University of Ottawa', r'University of Saskatchewan',
            r'York University', r'University of Manitoba', r'Carleton University',
            r'Concordia University', r'University of Victoria',
            r'Ryerson University', r'University of Guelph', r'Laval University',
            r'Memorial University of Newfoundland', r'University of Windsor',
            r'Brock University', r'University of New Brunswick',
            r'Centre de Recherche en Infectiologie de', r'Toronto-Dominion Bank',
            r'Shopify', r'Bank of Nova Scotia (Scotiabank)',
            r'Bell Canada Enterprises', r'Canadian National Railway',
            r'Manulife Financial', r'Canadian Natural Resources Limited',
            r'Barrick Gold', r'Canadian Imperial Bank of Commerce',
            r'Telus Corporation', r'Brookfield Asset Management',
            r'George Weston Limited', r'Rogers Communications', r'BCE Inc',
            r'Sun Life Financial', r'Loblaw Companies', r'Burnaby',
            r'Alimentation Couche-Tard', r'Power Corporation of Canada',
            r'Magnate, International', r'Husky Energy', r'Bombardier',
            r'Imperial Oil',
            r'Centre de Recherche en Infectiologie de l\'Université Laval, CHUQ',
            r'university health network', r'Queen\'s University Kingston',
            r'Cross Cancer Institute', r'Scotiabank', r'Bell Canada',
            r'Teck Resources', r'Loblaw Companies Limited', r'Pembina Pipeline',
            r'Hydro-Québec', r'TransCanada Corporation', r'TC Energy',
            r'Universite de sherbrooke',
        ],
        'UK': [
            r'Oxford', r'Cambridge', r'Imperial', r'London',
            r'University College London', r'King\'s College', r'Edinburgh',
            r'Manchester', r'Bristol', r'Warwick', r'Southampton', r'Durham',
            r'St Andrews', r'London Business School', r'University of Bath',
            r'Glasgow', r'Birmingham', r'Leeds', r'Sheffield', r'Nottingham',
            r'Exeter', r'Lancaster', r'Newcastle University', r'St.?Andrews',
            r'Wellcome Trust Sanger Institute',
            r'Royal (Dick) School of Veterinary Studies',
            r'Wellcome Trust Sanger Institute Hinxton', r'Harlow UK',
            r'Cardiff University', r'Wellcome Sanger Institute',
            r'AFRC Institute of Arable Crops Research',
            r'Dagenham Research Centre', r'University of Reading', r'Norwich',
            r'Wellcome Research Laboratories', r'Wellcome trust',
            r'University of Bradford', r'Rothamsted Experimental Station',
            r'School of Physiology, Pharmacology & Neuroscience', r'Bath Road',
            r'East Anglia', r'John Radcliffe Hospital', r'University of York',
            r'CellTech Therapeutics', r'Keele University',
            r'Central Veterinary Research Laboratories', r'University of Essex',
            r'John Innes Centre, Norwich Research Park Colney Norwich',
            r'Biochemistry Department, Rothamsted Experimental Station, Harpenden',
            r'University of Surrey', r'Institute Of Photonics',
            r'Department of Pathology and Laboratory Medicine',
            r'University of Aberdeen', r'University of Leicester',
            r'Loughborough University',
            r'Inst Canc Res, Breakthrough Breast Canc Res Ctr',
            r'John Innes Centre', r'University of Wales College of Medicine',
            r'BBC Research Department', r'Surrey', r'Rothamsted Research',
            r'Cancer Research UK Clinical Trials Unit', r'University of Sussex',
            r'Aston University', r'University of Newcastle', r'Cancer Research UK',
            r'National Health Service', r'University of St\. Andrews', r'Essex',
            r'Royal Marsden NHS Foundation Trust', r'Swansea University',
            r'Norwich Medical School', r'Heriot Watt University', r'Diageo',
            r'GlaxoSmithKline', r'British Biotech Pharmaceuticals', r'DeepMind',
            r'Lloyds Banking Group', r'Rio Tinto', r'Reckitt Benckiser Group',
            r'Legal & General Group', r'National Grid plc', r'Prudential plc',
            r'Aviva', r'Anglo American plc', r'RELX plc',
            r'Scottish Mortgage Investment Trust', r'TESCO',
            r'Addenbrooke\'s Hospital', r'University of Dundee',
            r'University of Liverpool',
            r'National Institute for Biological Standards and Control',
            r'Cancer Research UK Clinical Trials Unit, CR UK Institute for Cancer Studies, Clinical Research Block',
        ],
        'Netherlands': [
            r'Royal Dutch Shell', r'Netherlands', r'Amsterdam', r'Rotterdam',
            r'Wageningen University.?Research', r'Leiden', r'Groningen',
            r'Erasmus', r'Utrecht', r'Maastricht', r'University of Twente',
            r'Radboud University Nijmegen', r'Eindhoven University of Technology',
            r'VU University Medical Centre',
            r'Zernike Institute for Advanced Materials', r'Enschede',
            r'Akzo‐Nobel', r'Radboud University', r'Akzo.?Nobel',
            r'Faculteit Medische Wetenschappen/UMCG', r'Vrije University',
            r'Xsens Technol', r'VU medisch centrum',
            r'Centrum Wiskunde & Informatica', r'Royal Dutch Shell',
            r'ASML Holding', r'Unilever', r'Philips', r'ABN AMRO Bank', r'KPN',
            r'Heineken', r'AkzoNobel', r'Ahold Delhaize',
        ],
        'Australia': [
            r'BHP Group', r'Australian National', r'Sydney', r'Melbourne',
            r'New South Wales', r'UNSW', r'Queensland', r'Monash',
            r'Western Australia', r'Adelaide', r'Technology Sydney', r'Wollongong',
            r'Macquarie', r'Curtin', r'RMIT', r'South Australia', r'Deakin',
            r'St\. Vincent\'s Institute of Medical Research',
            r'Flinders University', r'Baker IDI Heart & Diabetes Institute',
            r'Griffith University', r'Royal Prince Alfred Hospital',
            r'Prince Henry\'s Institute of Medical Research',
            r'Baker Heart Research Institute',
            r'Australasian Drug Information Services', r'University of Newcastle',
            r'Royal North Shore Hospital', r'Tasmania',
            r'Prince of Wales Hospital', r'Medicine Alfred Hospital',
            r'Alfred Hospital', r'Alfred Health', r'Royal Perth Hospital',
            r'FLINDERS MEDICAL CENTRE', r'Peter MacCallum Cancer Centre',
            r'Walter and Eliza Hall Institute of Medical Research', r'CSIRO',
            r'Epidemiology and Preventive Medicine Alfred Hospital', r'BHP',
            r'Telstra', r'CSL', r'Rio Tinto', r'Transurban', r'Goodman',
            r'Afterpay', r'Westpac Banking', r'Woodside Petroleum',
        ],
        'Switzerland': [
            r'Switzerland', r'Zurich', r'Zürich', r'Lausanne', r'Universität Bern',
            r'University of Bern', r'Basel', r'University of GENEVA', r'geneva',
            r'CIBA.?GEIGY', r'Berne', r'Swiss Federal Institute of Technology',
            r'Swiss tropical and Public health Institute',
            r'Swiss Institute for Experimental Cancer Research',
            r'Federal Department of Communications', r'Roche Holding', r'UBS',
            r'Credit Suisse Group', r'ABB', r'Zurich Insurance', r'LafargeHolcim',
            r'F Hoffmann-La Roche AG', r'Hoffmann‐La Roch',
        ],
        'Italy': [
            r'Universita degli Studi di Genova', r'Numonyx, Agrate Brianza',
            r'Rome', r'Milan', r'Naples', r'Turin', r'Palermo', r'Genoa',
            r'Bologna', r'Florence', r'Venice', r'University of Ferrara',
            r'Messina', r'Pisa', r'Sicily', r'Tuscany', r'Lombardy', r'Sardinia',
            r'Piedmont', r'Universita’ Vita-Salute San Raffaele', r'Padova',
            r'Catanzaro', r'Brescia', r'IRCCS Ospedale San Raffaele',
            r'Fondazione IRCCS Istituto Nazionale dei Tumori',
            r'University of Catania', r'Istituto Oncologico Candiolo',
            r'Istituto Superiore di Sanità', r'Istituto Europeo di Oncologia',
            r'Giannina Gaslini', r'Istituto Clinico Humanitas',
            r'Fondazione Istituto Auxologico Italiano',
            r'Fondazione IRCCS Ca\' Granda Ospedale Maggiore Policlinico',
            r'IRCCS Fondazione Policlinico San Matteo',
            r'Istituto Nazionale Tumori Regina Elena', r'University of Bari',
            r'Fondazione Telethon', r'Universita degli Studi dell\' Insubria',
            r'Universita Autonoma di Bari', r'Centro di Riferimento Oncologico',
            r'Università Politecnica delle Marche', r'University of Cagliari',
            r'University of Campania.?Luigi Vanvitelli',
            r'Azienda Sanitaria Ospedaliera Molinette San Giovanni Battista Di Torino',
            r'University Hospital of Parma', r'Universita di Ferrara',
            r'Ospedale Bellaria', r'Istituto Neurologico Casimiro Mondino',
            r'Istituto Nazionale per le Malattie Infettive Lazzaro Spallanzani',
            r'Umberto I Hospital', r'Policlinico Universitario P\. Giaccone',
            r'University of Verona', r'Centro Cardiologico Monzino',
            r'Nerviano Medical Sciences',
            r'Istituti Clinici Scientifici Maugeri Spa', r'IRCCS', r'C\. Besta',
            r'Laboratori Negri Bergamo', r'Istituto Regina Elena',
            r'Arcispedale Santa Maria Nuova', r'University of Chieti',
            r'Siena Univ', r'University of Pavia', r'University of Perugia',
            r'Istituto Nazionale Tumori Fondazione G\. Pascale',
            r'Fondazione Santa Lucia', r'University of Siena',
            r'University of Padua', r'Sant\'Andrea Hospital',
            r'University of L\'Aquila', r'Trento',
            r'Azienda Ospedaliera San Gerardo Monza',
            r'University of Modena and Reggio Emilia',
            r'Istituti Ortopedici Rizzoli', r'European Institute of Oncology',
            r'University of Parma', r'Ospedali Riuniti Di Bergamo',
            r'Universita di\' Torino', r'Italian Multiple Myeloma Study Group',
            r'Ospedale Luigi Sacco', r'Università del Piemonte orientale',
            r'Vita-Salute San Raffaele University', r'University of Torino',
            r'Fiat Chrysler Automobiles', r'Eni', r'Luxottica Group', r'Ferrari',
            r'Pirelli', r'Leonardo S\.p\.A\.', r'Prada', r'Gucci', r'Armani',
            r'Mediaset',
        ],
        'United States': [
            r'Agere Systems', r'Virginia Commonwealth University',
            r'Quantum Dot Corporation, Hayward',
        ],
        'New Zealand': [
            r'Auckland', r'Waikato', r'Massey', r'Wellington', r'Canterbury',
            r'Lincoln University', r'Otago', r'Fletcher Building',
            r'Spark New Zealand', r'Meridian Energy',
            r'Auckland International Airport', r'Contact Energy', r'Mainfreight',
            r'Ryman Healthcare', r'Kathmandu Holdings', r'Air New Zealand',
            r'SkyCity Entertainment',
        ],
        'Malaysia': [
            r'Universiti', r'Malaya', r'Kebangsaan', r'Putra', r'Sains',
            r'Teknologi', r'Utara', r'Sarawak', r'Sabah', r'Maybank',
            r'Tenaga Nasional Berhad', r'CIMB Group Holdings Berhad',
            r'Public Bank Berhad', r'Top Glove Corporation Berhad',
            r'Hartalega Holdings Berhad', r'Sime Darby Berhad',
            r'IOI Corporation Berhad', r'Genting Group',
        ],
        'India': [
            r'Delhi', r'Bombay', r'Kanpur', r'Madras', r'Kharagpur',
            r'Indian Institute of Technology', r'Bangalore', r'Jawaharlal Nehru',
            r'Banaras Hindu', r'Varanasi', r'Aligarh Muslim', r'Aligarh',
            r'Hyderabad', r'Osmania', r'Pune', r'Calcutta', r'Manipal',
            r'Vellore Institute of Technology', r'Anna', r'Chennai', r'Gujarat',
            r'Mumbai', r'Jamia Millia Islamia', r'Lovely Professional', r'Amity',
            r'Jadavpur', r'Kolkata', r'Punjab', r'Mysore', r'Tata', r'Infosys',
            r'Wipro', r'HDFC Bank', r'ICICI Bank', r'Adani', r'Mahindra', r'Bajaj',
            r'Tata Consultancy Services', r'Larsen & Toubro',
            r'Hindustan Unilever', r'Axis Bank', r'Reliance Jio Infocomm',
            r'Tech Mahindra', r'Asian Paints', r'Bharti Airtel',
        ],
        'Belgium': [
            r'Structural Biology Brussels', r'imec', r'Leuven', r'Brussel',
            r'Bruxelles', r'Plant Genetic Systems N\.V\., Gent',
            r'Centre Hospitalier Universitaire de Liège',
            r'Université libre de Bruxelles',
        ],
        'Spain': [
            r'University of Granada',
        ],
        'South Korea': [
            r'Korea', r'Seoul', r'Korea Advanced Institute of Science.?Technology',
            r'Yonsei', r'Inha University', r'Hanyang University',
            r'Kyungpook National University', r'Ewha Womans University',
            r'ChungNam National', r'SungKyunKwan', r'Daejeon',
            r'University of Ulsan', r'Gyeonggi-Do', r'Chonnam National',
            r'Ajou University', r'Chonbuk National University', r'Jeonju',
            r'Kangwon National', r'SKKU Advanced Institute of Nanotechnology',
            r'Kookmin UniversityGyeongsang National', r'Sogang University',
            r'Sungshin Women\’s University', r'Jeonbuk National\.', r'Chung-Ang',
            r'CHA University', r'Gyeongsang', r'Hallym Uni', r'Chosun',
            r'SoonChunHyang', r'Sejong', r'ChungBuk National', r'Gachon',
            r'Myongji', r'Pusan National',
            r'Gwangju Institute of Science and technology',
            r'Electronics and Telecommunications Research Institute',
            r'Yeungnam University', r'Samsung', r'POSCO', r'SK Innovation',
            r'R&D Center, ATD, Hwasung', r'Hyundai Heavy Industries',
            r'Lotte Group',
        ],
        'Russia': [
            r'Russian', r'Moscow', r'Saint Petersburg State University',
            r'Novosibirsk State University', r'Tomsk State University',
            r'National Research Nuclear University MEPhI',
            r'Siberian Federal University', r'Ural Federal University', r'Rosneft',
            r'Lukoil', r'Norilsk Nickel', r'Novatek', r'Rostec', r'Yandex',
            r'Mobile TeleSystems', r'Mail\.Ru',
        ],
        'Sweden': [
            r'Lund', r'Uppsala', r'Gothenburg',
            r'Chalmers University of Technology', r'Stockholm', r'Karolinska',
            r'Linköping', r'Royal Institute of Technology', r'Umeå', r'Swedish',
            r'University of Borås', r'Ophthalmology \(Malmö\)',
            r'Örebro University', r'Sahlgrenska University Hospital', r'Ericsson',
            r'IKEA', r'BioInvent Therapeutic',
        ],
        'Norway': [
            r'Oslo', r'University of Bergen',
            r'Norwegian University of Science and Technology',
            r'University of Tromsø', r'Norwegian University',
            r'University of Stavanger', r'Norwegian School',
            r'Western Norway University of Applied Sciences', r'Statoil',
        ],
        'Taiwan': [
            r'National Cheng Kung University', r'Asia University',
            r'National TsingHua', r'Taipei', r'Hsinchu', r'Yunlin', r'Taichung',
            r'National Yang Ming Chiao Tung University',
            r'National Yang.?Ming University', r'Chung.?Hsing University',
            r'National Tsing Hua', r'National Central University', r'Tainan',
            r'National Chiao Tung', r'chang gung university',
            r'Kaohsiung Medical University', r'ITRI, Chutung',
            r'Institute of BioAgricultural Sciences, Academia Sinica',
            r'Academia Sinica - Institute of Biomedical Sciences',
            r'Tamkang university', r'Academia Sinica',
            r'National Chung.?Cheng University',
            r'Academia Sinica Institute of Atomic and Molecular Sciences',
            r'Macronix International',
        ],
        'Hong Kong': [
            r'Hong Kong Hospital Authority',
        ],
        'Saudi Arabia': [
            r'Saudi ARAMCO', r'King Abdullah University of Science.?Technology',
            r'King Fahd University of Petroleum and Minerals',
        ],
        'Moldova': [
            r'Kishinev',
        ],
        'Ireland': [
            r'Dublin', r'University College Cork',
        ],
        'Serbia': [
            r'Belgrade',
        ],
        'Turkey': [
            r'Hacettepe University', r'Middle East Technical University',
        ],
        'Czech': [
            r'Czech Acad\. Of Sciences', r'Charles University',
        ],
        'Iran': [
            r'Tehran',
        ],
        'Slovakia': [
            r'Slovak Academy of Sciences',
        ],
        'Lithuania': [
            r'Vilnius', r'Lithuania',
        ],
        'Greece': [
            r'Aristotle University of Thessaloniki', r'Athens',
            r'National Technical Univ\. of Athens', r'University of patras',
            r'Foundation For Research And Technology-Hellas',
        ],
        'Portugal': [
            r'Coimbra', r'Porto', r'Univ\. of Minho',
        ],
        'Poland': [
            r'Polish Academy of Sciences', r'University of Warsaw',
            r'Medical University of Gdańsk',
        ],
        'Mexico': [
            r'Instituto Nacional de Medicina Genomica',
            r'Universidad autónoma de Ciudad Juárez',
        ],
        'Kuwait': [
            r'Kuwait Cancer Control Center', r'Kuwait',
        ],
        'Iceland': [
            r'Decode genetics',
        ],
        'Cyprus': [
            r'Cyprus', r'Nicosia',
        ],
        'Slovenia': [
            r'Ljubljana',
        ],
        'Luxembourg': [
            r'University of Luxembourg',
        ],
        'Oman': [
            r'Petroleum Development Oman',
        ],
        'Venezuela': [
            r'PDVSA-Intevep',
        ],
        'Croatia': [
            r'Zagreb',
        ],
        'Indonesia': [
            r'Indonesia',
            r'Primate Research Center Bogor Agricultural University Bogor Indonesia',
        ],
        'Austria': [
            r'Austrian', r'Vienna', r'Innsbruck', r'University of Graz',
            r'Graz University of Technology', r'Medical University of Graz',
            r'Johannes Kepler University Linz', r'University of Salzburg',
            r'Research Institute of Molecular Pathology',
        ],
    }

    result = ''
    for pattern in US_state:
        if re.search(pattern, input_string, re.IGNORECASE):
            result = 'USA'
    
    for country, patterns in city_state_match.items():
        if result == 'USA' and country == 'USA':
            continue
        for pattern in patterns:
            if re.search(r'\b' + pattern + r'\b', input_string, re.IGNORECASE):
                if not result:
                    result = country
                else:
                    result = '!' + result + country
                break
    return result if result else None