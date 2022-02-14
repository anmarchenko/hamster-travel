defmodule HamsterTravel do
  @moduledoc """
  HamsterTravel keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def plans() do
    [
      %{
        id: 1,
        name: "Рождественский Стокгольм",
        slug: "rozhdestvenskiy-stokgolm",
        duration: 4,
        start_date: ~D[2021-12-17],
        status: "planned",
        countries: ["se"],
        people_count: 3,
        cover:
          "https://images.unsplash.com/photo-1572225303717-a96db5e8d8b0?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1887&q=80",
        budget: Decimal.new("1124.59"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [
          %{
            id: 434_343,
            city: %{
              country: "se",
              name: "Стокгольм"
            },
            day_intervals: [[0, 3]]
          }
        ],
        transfers: [],
        hotels: [],
        activities: [],
        notes: [],
        expenses: []
      },
      %{
        id: 2,
        name: "Будапешт и Тапольца",
        slug: "budapesht-i-tapoltsa",
        duration: 8,
        start_date: ~D[2021-09-07],
        status: "finished",
        countries: ["hu"],
        people_count: 3,
        cover:
          "https://images.unsplash.com/photo-1549877452-9c387954fbc2?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3870&q=80",
        budget: Decimal.new("1431.28"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [],
        transfers: [],
        hotels: [],
        activities: [],
        notes: [],
        expenses: []
      },
      %{
        id: 3,
        name: "Мальорка",
        slug: "maljorka",
        duration: 9,
        start_date: ~D[2021-07-13],
        status: "finished",
        countries: ["es"],
        people_count: 3,
        cover:
          "https://images.unsplash.com/photo-1617093888347-f73de2649f94?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3870&q=80",
        budget: Decimal.new("2939.65"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [],
        transfers: [],
        hotels: [],
        activities: [],
        notes: [],
        expenses: []
      },
      %{
        id: 4,
        name: "Копенгаген и немного Швеции",
        slug: "kopengagen-i-nemnogo-shvetsii",
        duration: 4,
        start_date: ~D[2019-05-16],
        status: "finished",
        countries: ["dk", "se"],
        people_count: 3,
        cover:
          "https://images.unsplash.com/photo-1643288939906-5c6c60c9d289?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3432&q=80",
        budget: Decimal.new("1171.76"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [
          %{
            id: 32,
            city: %{
              country: "dk",
              name: "Копенгаген"
            },
            day_intervals: [[0, 3]]
          },
          %{
            id: 1,
            city: %{
              country: "se",
              name: "Мальмё"
            },
            day_intervals: [[2, 2]]
          },
          %{
            id: 2,
            city: %{
              country: "se",
              name: "Лунд"
            },
            day_intervals: [[2, 2]]
          }
        ],
        transfers: [
          %{
            id: 1,
            day_index: 0,
            type: "plane",
            station_from: "TXL",
            station_to: "CPN",
            time_from: "10:45",
            time_to: "11:55",
            city_from: %{
              name: "Берлин",
              country: "de"
            },
            city_to: %{
              name: "Копенгаген",
              country: "dk"
            },
            price: Decimal.new("85.06"),
            price_currency: "EUR",
            vehicle_id: nil,
            company: "Easyjet",
            comment: nil,
            links: [
              "https://www.easyjet.com/en",
              "https://www.easyjet.com/en"
            ]
          },
          %{
            id: 2,
            day_index: 2,
            type: "train",
            station_from: nil,
            station_to: "Centralstation",
            time_from: "08:47",
            time_to: "09:26",
            city_from: %{
              name: "Копенгаген",
              country: "dk"
            },
            city_to: %{
              name: "Мальмё",
              country: "se"
            },
            price: Decimal.new("182"),
            price_currency: "DKK",
            vehicle_id: "Re 1028",
            company: "DSB",
            comment: "Купить билеты в автомате на платформе",
            links: []
          },
          %{
            id: 3,
            day_index: 2,
            type: "train",
            station_from: "Centralstation",
            station_to: "Centralstation",
            time_from: "12:11",
            time_to: "12:24",
            city_from: %{
              name: "Мальмё",
              country: "se"
            },
            city_to: %{
              name: "Лунд",
              country: "se"
            },
            price: Decimal.new("106"),
            price_currency: "SEK",
            vehicle_id: "1714",
            company: "Skånetrafiken",
            comment: nil,
            links: []
          },
          %{
            id: 4,
            day_index: 2,
            type: "train",
            station_from: "Centralstation",
            station_to: "H",
            time_from: "15:40",
            time_to: "16:28",
            city_from: %{
              name: "Лунд",
              country: "se"
            },
            city_to: %{
              name: "Копенгаген",
              country: "dk"
            },
            price: Decimal.new("300"),
            price_currency: "SEK",
            vehicle_id: "1714",
            company: "Skånetrafiken",
            comment: nil,
            links: []
          },
          %{
            id: 5,
            day_index: 3,
            type: "plane",
            station_from: "CPN",
            station_to: "TXL",
            time_from: "17:20",
            time_to: "18:20",
            city_from: %{
              name: "Копенгаген",
              country: "dk"
            },
            city_to: %{
              name: "Берлин",
              country: "de"
            },
            price: Decimal.new("70.14"),
            price_currency: "EUR",
            vehicle_id: nil,
            company: "Easyjet",
            comment: nil,
            links: [
              "https://www.easyjet.com/en"
            ]
          }
        ],
        hotels: [
          %{
            id: 1,
            name: "Скандинавская уютная квартира",
            day_intervals: [[0, 3]],
            price: Decimal.new("132"),
            price_currency: "EUR",
            price_type: :per_night,
            comment: "Фредериксберг, Дания",
            links: [
              "https://www.airbnb.ru/rooms/21433516?location=Копенгаген%2C%20Дания&adults=2&infants=1&check_in=2019-05-16&check_out=2019-05-19&home_collection=1&s=quWwV675"
            ]
          }
        ],
        activities: [
          %{
            id: 1,
            day_index: 0,
            position: 0,
            name: "Копенгаген",
            comment:
              "Копенгаген — столица и самый крупный город Дании. Располагается на островах Зеландия, Слотсхольмен и Амагер. Население исторического города составляет чуть более 0,5 млн человек, с пригородами — более 1 млн жителей. Часть города — самопровозглашённый Свободный город Христиания — находится на частичном самоуправлении.  Город является культурным, экономическим и правительственным центром Дании; это один из крупнейших финансовых центров Северной Европы с Копенгагенской фондовой биржей. Экономика Копенгагена имела быстрое развитие в секторе услуг, особенно посредством инициатив в информационных технологиях, фармацевтике и чистой технологии. После завершения строительства Эресуннского моста Копенгаген стал более интегрированым со шведской провинцией Скания и её крупнейшим городом Мальме, образуя Эресуннский регион.",
            link: nil,
            operation_times: nil,
            address: nil,
            price: Decimal.new("0"),
            price_currency: "EUR",
            priority: "should"
          },
          %{
            id: 2,
            day_index: 0,
            position: 1,
            name: "Церковь Грундтвига",
            comment: """
            Церковь Грундтвига (дат. Grundtvigs Kirke) — лютеранская церковь, принадлежащая Народной Церкви Дании и расположенная в Копенгагене, в районе Биспебьерг (Bispebjerg). Названа в честь датского богослова, церковного деятеля и писателя Н.-Ф.-C. Грундтвига. Является одной из самых знаменитых церквей города и редчайшим примером культового сооружения, построенного в стиле экспрессионизма.

            Конкурс проектов будущей церкви был объявлен в 1913 году; выиграл его архитектор Педер Клинт. Строительство началось только в 1921 году и продолжалось пять лет. Последние работы по отделке интерьера проводились в 1940 году под руководством Кааре Клинта, сына строителя церкви.

            В архитектуре храма переплетаются черты традиционных датских деревенских церквей, готики, барокко и разнообразных модернистских течений. Строительным материалом для церкви служил жёлтый кирпич (также характерная черта датской церковной архитектуры).
            """,
            link: "http://www.grundtvigskirke.dk/",
            operation_times:
              "вт, ср, пт, сб: 9.00 - 16.00; чт: 9.00 - 18.00; вс: 12.00 - 16.00; пн: закрыто",
            address: "På Bjerget 14B, 2400 København NV, Дания",
            price: Decimal.new("0"),
            price_currency: "DKK",
            priority: "must"
          },
          %{
            id: 3,
            day_index: 1,
            position: 0,
            name: "Русалочка (статуя)",
            comment: """
            Русалочка (дат. Den Lille Havfrue, в дословном переводе — «Морская дамочка») — статуя, изображающая персонажа из сказки «Русалочка» Ганса Христиана Андерсена. Расположена в порту Копенгагена. Скульптура 1,25 м высотой и весит около 175 кг.

            Автор — датский скульптор Эдвард Эриксен. Открыта 23 августа 1913 года.

            Изготовлена по заказу сына основателя пивоварни «Carlsberg» — Карла Якобсена, который был очарован балетом по сказке Русалочка в Королевском театре Копенгагена. Он просил прима-балерину Эллен Прайс быть моделью для статуи. Но Прайс отказалась позировать в обнажённом виде, и скульптор использовал её только в качестве модели для головы «Русалочки», а моделью для фигуры «Русалочки» послужила жена самого скульптора Элине Эриксен.

            Русалочка стала одним из самых известных символов Копенгагена и всемирно известной достопримечательностью для туристов, о чём свидетельствует тот факт, что во многих городах установлены копии статуи. В частности, они есть в Саратове, Амстердаме, Париже, Риме, Токио, Шэньчжэне и Сиднее.

            Срок охраны авторских прав на статую не истёк, и наследники скульптора, умершего в 1959 году, требуют платы за использование её копий и изображений.

            Статуя многократно становилась объектом вандализма, начиная с середины 1960-х годов по разным причинам, но каждый раз была восстановлена:
            - 24 апреля 1964 — голова статуи была отпилена и похищена троцкистски настроенным движением художников[4]. Голова так и не была обнаружена, но статуя была восстановлена.
            - 22 июля 1984 — её правая рука была отпилена. Рука была возвращена через два дня, поступок совершили два подростка.
            - 1990 — очередная попытка похитить её голову. Результат — разрез глубиной 18 см на шее.
            - 6 января 1998 — она была обезглавлена снова. Виновники не были найдены. Голова была возвращена анонимно, оставлена рядом с телевизионной станцией. 4 февраля голову установили обратно.
            - Статуя была несколько раз испачкана красной краской, в том числе один раз в 1961 году, когда её волосы были окрашены в красный цвет и на ней был нарисован лифчик.
            - 11 сентября 2003 — статуя была сорвана с её постамента с помощью взрыва.
            - В 2004 году она была завёрнута в паранджу в знак протеста против переговоров о вступлении Турции в Европейский Союз.
            - 8 марта 2006 — к руке статуи был прикреплен фаллоимитатор, а статуя испачкана зелёной краской. Слова 8 марта были написаны на постаменте.
            - 3 марта 2007 — статуя была снова испачкана розовой краской.
            - Май 2007 — статуя была испачкана краской неизвестными вандалами.
            - 20 мая 2007 — была одета в мусульманское платье и хиджаб.
            - Май 2017 - памятник был облит красной краской.
            - 14 июня 2017 - памятник вновь облит краской, на этот раз сине-белой.

            В 2007 году власти Копенгагена объявили, что статуя может быть перенесена дальше в гавань, чтобы избежать дальнейших случаев вандализма и для предотвращения постоянных попыток туристов взобраться на неё.

            В 2010 году Русалочка впервые на несколько месяцев (c 25 марта по 31 октября) покинула Копенгаген и выставлялась в датском павильоне на Всемирной выставке в Шанхае. Во избежание актов вандализма маршрут перемещения статуи из Копенгагена в Шанхай и обратно держался в секрете, а на Всемирной выставке она находилась под постоянной охраной. На время отсутствия Русалочки в месте установки скульптуры существовала видеоинсталляция, выполненная китайским художником и диссидентом Ай Вейвеем.
            """,
            link: nil,
            operation_times: nil,
            address: "Langelinie, 2100 København Ø, Дания",
            price: Decimal.new("0"),
            price_currency: "DKK",
            priority: "must"
          },
          %{
            id: 4,
            day_index: 1,
            position: 1,
            name: "Церковь Фредерика",
            comment: """
            Церковь Фредерика, также известная как Мраморная церковь (дат. Marmorkirken) — лютеранская церковь, одна из достопримечательностей Копенгагена.

            Проект здания был создан архитектором Николаем Эйгтведом в 1740 году. Местоположением новой церкви был выбран район Копенгагена Фредериксштаден.

            Первый камень в фундамент был заложен королём Фредериком V 31 октября 1749 года, однако строительство замедлилось в результате сокращения бюджетных ассигнований и смерти Эйгтведа в 1754 году. В 1770 году первоначальный проект церкви был отвергнут Иоганном Фридрихом Струэнзе. Церковь осталась недостроенной почти 150 лет.

            Проект, по которому построено здание, существующее в настоящее время, был создан Фердинандом Мелдалом, строительство финансировалось датским банкиром Карлом Фредериком Тьетгеном. Церковь была открыта 19 августа 1894 года.

            Здание имеет самый большой в регионе купол (его окружность составляет 31 метр), который опирается на двенадцать колонн.
            """,
            link: "http://www.marmorkirken.dk/",
            operation_times: "пн, вт, ср, чт, сб: 10:00 - 17:00; пт, вс: 12:00 - 17:00",
            address: "Frederiksgade 4, 1265 København, Дания",
            price: Decimal.new("0"),
            price_currency: "DKK",
            priority: "should"
          },
          %{
            id: 5,
            day_index: 1,
            position: 2,
            name: "Круглая башня",
            comment: """
            Круглая башня (Rundetårn) — обсерватория в составе комплекса университетских зданий, который был возведён в приходе копенгагенской церкви Троицы по приказу короля Кристиана IV в середине XVII века.

            Строительные работы, которые пришлись на 1637-42 гг., курировал Стенвинкель Младший. Обсерватория в башне является одной из старейших в Европе. В XVII—XVIII вв. здесь трудились такие видные астрономы, как Оле Рёмер и Педер Хорребоу. Со временем башня стала одним из символов датской столицы. В сказке Андерсена «Огниво» сказано, что у самой большой собаки глаза такой величины, как Круглая башня.

            Верхний ярус башни, который поднимается на 36 метров над уровнем мостовой, занимает планетарий. Ступеней внутри нет. Наверх ведёт пологий винтовой подъём протяжённостью в 210 метров. Благодаря такому устройству в обсерваторию могли подниматься повозки и всадники на лошадях. По легенде, в 1716 г. такой подъём совершил Пётр Первый, за которым последовала его супруга в карете, запряжённой шестёркой лошадей. В 1902 г. на вершину Круглой башни впервые поднялся автомобиль.

            На внешней стене башни высечено имя Божье из четырех позолоченных еврейских букв (тетраграмматон). Надпись была собственноручно составлена Кристианом IV. Автограф короля хранится в Датском национальном архиве.

            Ещё Рёмер, заметив невыгодность башни для проведения наблюдений, стал проводить исследования у себя дома. Постоянные подъёмы гружёных кладью повозок на верх башни не лучшим образом сказывались на её состоянии. Ныне обсерватория имеет любительский статус, а соответствующее подразделение университета с 1861 г. выведено за пределы датской столицы.

            Круглая башня упоминается в сказке Андерсена "Огниво"
            """,
            link: nil,
            operation_times: nil,
            address: "Købmagergade 52A, 1150 København, Дания",
            price: Decimal.new("50"),
            price_currency: "DKK",
            priority: "should"
          },
          %{
            id: 6,
            day_index: 1,
            position: 3,
            name: "Новый театр",
            comment: """
            Новый театр (дат. Det Ny Teater) — театр в Копенгагене, открытый 19 сентября 1908 года. Расположен в одном из центральных районов города — Вестербро. Зрительный зал рассчитан на более 1000 мест, а площадь помещений театра составляет более 12 тыс. м².

            Здание театра спроектировано архитекторами Людвигом Андерсеном и Л. П. Гудме, причём первоначальный проект был создан Л. П. Гудме в 1907 году, а под руководством Андерсена театр был возведён в изменённом виде на изначальном фундаменте. Последовал судебный процесс, в результате которого Людвиг Андерсен был исключён из Датской ассоциации архитекторов.

            Первым представлением в Новом театре стала комедия Пьера Бертона (Pierre Bertons) «Den skønne Marseillanerinde», главные роли в которой исполнили известные датские актёры Аста Нильсен (Asta Nielsen) и Поль Роймерт (Poul Reumert). В 1990 году театр был закрыт на неопределённый срок из-за ветхости. После реставрации, получившей награду федерации Europa Nostra, Новый театр был открыт в 1994 году.

            Среди многих представлений в Новом театре были поставлены «Отверженные», «Призрак Оперы», «Красавица и Чудовище», «Кошки», «Весёлая вдова», «Иисус Христос — суперзвезда».
            """,
            link: nil,
            operation_times: nil,
            address: "Gammel Kongevej 29, 1610 København V, Дания",
            price: Decimal.new("0"),
            price_currency: "DKK",
            priority: "irrelevant"
          }
        ],
        notes: [
          %{
            id: 1,
            text: "Посчитать разницу с картой и без",
            day_index: 0
          }
        ],
        expenses: [
          %{
            id: 1,
            name: "Дорога в аэропорт",
            price: Decimal.new("3.40"),
            price_currency: "EUR",
            day_index: 0
          },
          %{
            id: 2,
            name: "Дорога в аэропорт",
            price: Decimal.new("72"),
            price_currency: "DKK",
            day_index: 0
          },
          %{
            id: 3,
            name: "Проезд",
            price: Decimal.new("48"),
            price_currency: "DKK",
            day_index: 0
          },
          %{
            id: 4,
            name: "Мед. страховка",
            price: Decimal.new("4.80"),
            price_currency: "EUR",
            day_index: 0
          },
          %{
            id: 5,
            name: "Дневные билеты",
            price: Decimal.new("160"),
            price_currency: "DKK",
            day_index: 1
          },
          %{
            id: 6,
            name: "Сувениры",
            price: Decimal.new("75"),
            price_currency: "DKK",
            day_index: 1
          },
          %{
            id: 7,
            name: "Дневные билеты",
            price: Decimal.new("160"),
            price_currency: "DKK",
            day_index: 2
          },
          %{
            id: 8,
            name: "Сувениры в Мальмё",
            price: Decimal.new("100"),
            price_currency: "SEK",
            day_index: 2
          },
          %{
            id: 9,
            name: "Сувениры в Лего",
            price: Decimal.new("180"),
            price_currency: "DKK",
            day_index: 2
          },
          %{
            id: 10,
            name: "Сувениры в Лунде",
            price: Decimal.new("49"),
            price_currency: "SEK",
            day_index: 2
          },
          %{
            id: 11,
            name: "Аттракционы в Тиволи",
            price: Decimal.new("150"),
            price_currency: "DKK",
            day_index: 3
          },
          %{
            id: 12,
            name: "Камера хранения",
            price: Decimal.new("70"),
            price_currency: "DKK",
            day_index: 3
          },
          %{
            id: 13,
            name: "Сувениры",
            price: Decimal.new("130"),
            price_currency: "DKK",
            day_index: 3
          }
        ]
      }
    ]
  end

  def drafts() do
    [
      %{
        id: 5,
        name: "Бамберг - пивной город Франконии ",
        slug: "bamberg-pivnoy-gorod",
        duration: 3,
        start_date: nil,
        status: "draft",
        countries: ["de"],
        people_count: 2,
        cover:
          "https://images.unsplash.com/photo-1607338533044-c5bc1ec32bde?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1887&q=80",
        budget: Decimal.new("614.18"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [],
        transfers: [],
        hotels: [],
        activities: [],
        notes: [],
        expenses: []
      },
      %{
        id: 6,
        name: "Гельголанд: в гости к тюленюшкам! ",
        slug: "gelgoland-v-gosti-k-tyul",
        duration: 2,
        start_date: nil,
        status: "draft",
        countries: ["de"],
        people_count: 1,
        cover:
          "https://images.unsplash.com/photo-1559157695-c3e284ea6c2b?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3870&q=80",
        budget: Decimal.new("90"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [],
        transfers: [],
        hotels: [],
        activities: [],
        notes: [],
        expenses: []
      }
    ]
  end

  def find_plan_by_slug(slug) do
    plan =
      Enum.find(plans() ++ drafts(), fn plan ->
        plan.slug == slug
      end)

    if plan != nil do
      {:ok, plan}
    else
      {:error, :not_found}
    end
  end

  def filter_places_by_day(places, day_index) do
    Enum.filter(places, fn pl -> intersects_day(pl, day_index) end)
  end

  def filter_hotels_by_day(hotels, day_index) do
    Enum.filter(hotels, fn hotel -> intersects_day(hotel, day_index) end)
  end

  def filter_transfers_by_day(transfers, day_index) do
    transfers
    |> Enum.filter(fn tr -> tr.day_index == day_index end)
    |> Enum.sort(fn l, r -> l.time_from <= r.time_from end)
  end

  def filter_activities_by_day(activities, day_index) do
    activities
    |> Enum.filter(fn act -> act.day_index == day_index end)
    |> Enum.sort(fn l, r -> l.position <= r.position end)
  end

  def filter_expenses_by_day(expenses, day_index) do
    expenses
    |> Enum.filter(fn ex -> ex.day_index == day_index end)
  end

  def find_note_by_day(notes, day_index) do
    case Enum.filter(notes, fn n -> n.day_index == day_index end) do
      [] ->
        nil

      [note | _] ->
        note
    end
  end

  def fetch_budget(_, _) do
    Decimal.new(:rand.uniform(1000))
  end

  defp intersects_day(item, day_index) do
    Enum.any?(item.day_intervals, fn [l, r] ->
      day_index >= l && day_index <= r
    end)
  end
end
