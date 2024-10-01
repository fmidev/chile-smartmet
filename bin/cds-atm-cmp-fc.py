#!/usr/bin/env python3
import sys
import cdsapi
import yaml

with open('/home/users/smartmet/.cdsapirc', 'r') as f:
    credentials = yaml.safe_load(f)
print(credentials)
c = cdsapi.Client()
#url='https://ads-beta.atmosphere.copernicus.eu/api', key=credentials['key'])
year= sys.argv[1]
mon= sys.argv[2]
day= sys.argv[3]
date='%s-%s-%s'%(year,mon,day)
c.retrieve(
    'cams-global-atmospheric-composition-forecasts',
    {
        'date': [date+'/'+date],
        'type': ['forecast'],
        'data_format': 'grib',
        'variable': [
            'ammonium_aerosol_optical_depth_550nm', 'black_carbon_aerosol_optical_depth_550nm', 'dust_aerosol_optical_depth_550nm',
            'nitrate_aerosol_optical_depth_550nm', 'organic_matter_aerosol_optical_depth_550nm', 'particulate_matter_10um',
            'particulate_matter_1um', 'particulate_matter_2.5um', 'sea_salt_aerosol_optical_depth_550nm',
            'sulphate_aerosol_optical_depth_550nm', 'total_aerosol_optical_depth_1240nm', 'total_aerosol_optical_depth_469nm',
            'total_aerosol_optical_depth_550nm', 'total_aerosol_optical_depth_670nm', 'total_aerosol_optical_depth_865nm',
            'total_column_carbon_monoxide', 'total_column_ethane', 'total_column_formaldehyde',
            'total_column_hydrogen_peroxide', 'total_column_hydroxyl_radical', 'total_column_isoprene',
            'total_column_methane', 'total_column_nitric_acid', 'total_column_nitrogen_dioxide',
            'total_column_nitrogen_monoxide', 'total_column_ozone', 'total_column_peroxyacetyl_nitrate',
            'total_column_propane', 'total_column_sulphur_dioxide', 'uv_biologically_effective_dose',
            'uv_biologically_effective_dose_clear_sky',
        ],
        'time': '00:00',
        'leadtime_hour': [
            '0', '1', '10',
            '100', '101', '102',
            '103', '104', '105',
            '106', '107', '108',
            '109', '11', '110',
            '111', '112', '113',
            '114', '115', '116',
            '117', '118', '119',
            '12', '120', '13',
            '14', '15', '16',
            '17', '18', '19',
            '2', '20', '21',
            '22', '23', '24',
            '25', '26', '27',
            '28', '29', '3',
            '30', '31', '32',
            '33', '34', '35',
            '36', '37', '38',
            '39', '4', '40',
            '41', '42', '43',
            '44', '45', '46',
            '47', '48', '49',
            '5', '50', '51',
            '52', '53', '54',
            '55', '56', '57',
            '58', '59', '6',
            '60', '61', '62',
            '63', '64', '65',
            '66', '67', '68',
            '69', '7', '70',
            '71', '72', '73',
            '74', '75', '76',
            '77', '78', '79',
            '8', '80', '81',
            '82', '83', '84',
            '85', '86', '87',
            '88', '89', '9',
            '90', '91', '92',
            '93', '94', '95',
            '96', '97', '98',
            '99',
        ],
        'area': [-10, -80, -60, -50,],
    },
    '/data/cams-fc-%s%s%s-sam.grib'%(year,mon,day))