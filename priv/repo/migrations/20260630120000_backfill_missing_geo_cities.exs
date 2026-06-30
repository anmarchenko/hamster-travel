defmodule HamsterTravel.Repo.Migrations.BackfillMissingGeoCities do
  use Ecto.Migration

  def up do
    execute("""
    WITH city_values (
      name,
      name_ru,
      region_code,
      geonames_id,
      country_code,
      lat,
      lon,
      population
    ) AS (
      VALUES
        ('Grand''Anse', 'Гранд-Анс', '24', '241257', 'SC', -4.66667, 55.46667, 4140),
        ('La Digue', 'Ла-Диг', '25', '241303', 'SC', -4.35544, 55.83527, 3934),
        ('Baie Sainte Anne', 'Бе-Сент-Анн', '07', '6691843', 'SC', -4.31997, 55.75338, 5063),
        ('Grand''Anse', 'Гранд-Анс', '14', '8629285', 'SC', -4.33109, 55.72206, 4344),
        ('Silhouette Island', 'Силуэт', '11876017', '10629843', 'SC', -4.48599, 55.25262, 200),
        ('Anse aux Pins', 'Анс-о-Пен', '01', '10792304', 'SC', -4.686, 55.522, 4685),
        ('Pointe La Rue', 'Пуант-ля-Рю', '20', '10793687', 'SC', -4.67323, 55.5131, 3750),
        ('Baie Lazare', 'Бэ-Лазар', '06', '10793745', 'SC', -4.74971, 55.4754, 4795),
        ('Ile au Cerf', 'Серф', '18', '11184853', 'SC', -4.63108, 55.49278, 60),
        ('Glacis', 'Гласис', '12', '11395546', 'SC', -4.57578, 55.4368, 4496),
        ('Poivre Nord', 'Пуавр-Нор', '29', '11694892', 'SC', -5.76667, 53.31667, 8),
        ('Roche Caïman', 'Рош-Кайман', '30', '11694896', 'SC', -4.6401, 55.46879, 3828),
        ('North Island', 'Норт-Айленд', '11876017', '11822653', 'SC', -4.39342, 55.24407, 152),
        ('English River', 'Ла-Ривьер-Англез', '26', '13527028', 'SC', -4.61365, 55.45475, 4236),
        ('Mont Fleuri', 'Мон-Флёри', '09', '13527029', 'SC', -4.62695, 55.45427, 4055),
        ('Plaisance', 'Плезанс', '18', '13527030', 'SC', -4.64085, 55.46179, 4622),
        ('Les Mamelles', 'Ле-Мамелль', '29', '13527031', 'SC', -4.64584, 55.46795, 2719),
        ('Desroches', 'Дерош', '02', '13527032', 'SC', -5.6903, 53.67087, 60),
        ('Aldabra', 'Альдабра', NULL, '13580085', 'SC', -9.42279, 46.47197, 12),
        ('Assumption', 'Ассампшен', NULL, '13580086', 'SC', -9.73461, 46.51281, 20),
        ('Árneshreppur', 'Árneshreppur', '44', '11103248', 'IS', 66.00371, -21.49981, 53),
        ('Syðradalur', 'Syðradalur', 'ST', '2611965', 'FO', 62.01882, -6.9086, 7),
        ('Oyrareingir', 'Oyrareingir', 'ST', '2615258', 'FO', 62.09921, -6.94553, 38),
        ('Líðin', 'Líðin', 'SU', '2617758', 'FO', 61.55, -6.83333, 60),
        ('Langasandur', 'Langasandur', 'ST', '2617970', 'FO', 62.23354, -7.04654, 41),
        ('Kolbeinagjógv', 'Kolbeinagjógv', 'ST', '2618537', 'FO', 62.1, -6.78333, 28),
        ('Innan Glyvur', 'Innan Glyvur', 'OS', '2619389', 'FO', 62.13333, -6.75, 81),
        ('Trou aux Biches', 'Trou aux Biches', '16', '933953', 'MU', -20.03301, 57.55033, 14706),
        ('Solférino', 'Solférino', '17', '934001', 'MU', -20.29083, 57.46722, 361),
        ('Rouge Terre', 'Rouge Terre', '16', '934065', 'MU', -20.04333, 57.56833, 10760),
        ('Rivière du Poste', 'Ривьер-дю-Пост', '20', '934092', 'MU', -20.42417, 57.56694, 2170),
        ('Bel Ombre', 'Бель-Омбр', '20', '934731', 'MU', -20.50222, 57.40611, 2417),
        ('Belle Vue Pilot', 'Belle Vue Pilot', '16', '934735', 'MU', -20.05486, 57.58365, 4518),
        ('Belle Vue Harel', 'Belle Vue Harel', '16', '934736', 'MU', -20.06583, 57.59417, 7607),
        ('Belle Vue Maurel', 'Belle Vue Maurel', '19', '934739', 'MU', -20.12028, 57.66361, 7607),
        ('Péreybère', 'Péreybère', '19', '1106611', 'MU', -19.99883, 57.5885, 5000),
        ('Petit Bel Air', 'Petit Bel Air', '14', '1106683', 'MU', -20.39986, 57.69513, 1000),
        ('Calodyne', 'Calodyne', '19', '8643380', 'MU', -20.00215, 57.64249, 6252),
        ('Anse La Raye', 'Anse La Raye', NULL, '10171149', 'MU', -19.99057, 57.63202, 6060),
        ('Lallmatie', 'Lallmatie', NULL, '11205637', 'MU', -20.01839, 57.58017, 11910),
        ('Thulusdhoo', 'Thulusdhoo', '38', '11428107', 'MV', 4.37421, 73.65269, 1801),
        ('Ndiyona', 'Ndiyona', '40', '876961', 'NA', -18.03892, 20.70058, 20633),
        ('Tsintsabis', 'Tsintsabis', '38', '3352604', 'NA', -18.76936, 17.9629, 4000),
        ('Oniipa', 'Oniipa', '38', '3354130', 'NA', -17.91667, 16.03333, 4740)
    )
    INSERT INTO cities (
      name,
      name_ru,
      region_code,
      geonames_id,
      country_code,
      lat,
      lon,
      population,
      inserted_at,
      updated_at
    )
    SELECT
      name,
      name_ru,
      region_code,
      geonames_id,
      country_code,
      lat,
      lon,
      population,
      NOW(),
      NOW()
    FROM city_values
    WHERE EXISTS (
      SELECT 1
      FROM countries
      WHERE countries.iso = city_values.country_code
    )
      AND (
        city_values.region_code IS NULL
        OR EXISTS (
          SELECT 1
          FROM regions
          WHERE regions.country_code = city_values.country_code
            AND regions.region_code = city_values.region_code
        )
      )
    ON CONFLICT (geonames_id) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM cities
    WHERE geonames_id IN (
      '241257',
      '241303',
      '6691843',
      '8629285',
      '10629843',
      '10792304',
      '10793687',
      '10793745',
      '11184853',
      '11395546',
      '11694892',
      '11694896',
      '11822653',
      '13527028',
      '13527029',
      '13527030',
      '13527031',
      '13527032',
      '13580085',
      '13580086',
      '11103248',
      '2611965',
      '2615258',
      '2617758',
      '2617970',
      '2618537',
      '2619389',
      '933953',
      '934001',
      '934065',
      '934092',
      '934731',
      '934735',
      '934736',
      '934739',
      '1106611',
      '1106683',
      '8643380',
      '10171149',
      '11205637',
      '11428107',
      '876961',
      '3352604',
      '3354130'
    )
    """)
  end
end
