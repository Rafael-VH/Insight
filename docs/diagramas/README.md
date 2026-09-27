# Diagramas de Insight

Versiones **simplificadas** (Mermaid) de los diagramas del proyecto, con enlace directo a su
**versión interactiva** alojada en GitHub Pages.

> Dashboard completo: <https://rafael-vh.github.io/Insight/>

---

## Insight · Arquitectura limpia

Clean Architecture del proyecto: presentación, dominio y datos, con la regla de dependencia apuntando al centro.

```mermaid
flowchart TB
  classDef backend fill:#dcfce7,stroke:#059669,color:#052e16;
  classDef database fill:#ede9fe,stroke:#7c3aed,color:#2e1065;
  classDef external fill:#e2e8f0,stroke:#64748b,color:#0f172a;
  classDef frontend fill:#dbeafe,stroke:#0891b2,color:#083344;

  subgraph B0["Presentación"]
    uikit(["Screens & Widgets<br/><small>UI por feature</small>"])
    blocs(["BLoCs & Controllers<br/><small>flutter_bloc · estado</small>"])
  end
  subgraph B1["Dominio · Dart puro"]
    entities["Entities<br/><small>modelo de negocio inmutable</small>"]
    usecases["Use Cases<br/><small>reglas de aplicación</small>"]
    repositories["Repository Ports<br/><small>contratos abstractos</small>"]
    core["Core compartido<br/><small>errores tipados + GetIt</small>"]
  end
  subgraph B2["Datos"]
    repositoriesimpl["Repository Impl<br/><small>implementan contratos</small>"]
    datamodels["Models<br/><small>DTO ↔ entidad</small>"]
    datasources["Data Sources<br/><small>persistencia / OCR</small>"]
  end
  subgraph B3["Frameworks & Drivers"]
    sharedprefs[("SharedPreferences<br/><small>sesiones + ajustes</small>")]
    mlkit("Google ML Kit<br/><small>reconocimiento OCR</small>")
    jsonio("JSON Export / Import<br/><small>respaldos de usuario</small>")
  end

  uikit -- "eventos / estado" --> blocs
  blocs -- "invoca caso de uso" --> usecases
  usecases -- "usa contrato" --> repositories
  usecases -- "opera entidades" --> entities
  repositoriesimpl -. "implementa" .-> repositories
  repositoriesimpl -- "persiste / lee" --> datasources
  datamodels -- "convierte a entidad" --> entities
  datasources -- "SharedPreferences" --> sharedprefs
  datasources -- "TextoRecognition" --> mlkit
  datasources -. "JSON" .-> jsonio
```

> Versión interactiva: <https://rafael-vh.github.io/Insight/diagramas/insight-clean-architecture/>

---

## Insight · Cómo se relaciona el código

Cómo se relaciona el código del proyecto: OCR, historial, ajustes y persistencia con SharedPreferences.

```mermaid
flowchart TB
  classDef backend fill:#dcfce7,stroke:#059669,color:#052e16;
  classDef database fill:#ede9fe,stroke:#7c3aed,color:#2e1065;
  classDef external fill:#e2e8f0,stroke:#64748b,color:#0f172a;
  classDef frontend fill:#dbeafe,stroke:#0891b2,color:#083344;

  subgraph B0["Insight · app 100% local (sin backend)"]
    uploadUi(["Subida de imagen<br/><small>UploadScreen + StatsUploadController</small>"])
    parser["MlbbParser + Validator<br/><small>regex → ParseResult · GameMode</small>"]
    historyUi(["Historial + Insights<br/><small>HistoryScreen · fl_chart · detalle</small>"])
    shellUi(["Shell + Ajustes/Tema<br/><small>MainScreen · SettingsBloc · ThemeBloc</small>"])
    ocrBloc["OcrBloc<br/><small>RecognizeImageText use case</small>"]
    uploadBloc["UploadBloc · guardar<br/><small>SaveStatsCollection use case</small>"]
    historyBloc["HistoryBloc<br/><small>LazySingleton · lista precargada</small>"]
    mlkit("Google ML Kit<br/><small>TextRecognizer OCR on-device</small>")
    historyRepo["HistoryRepository<br/><small>impl + LocalStorageDataSource</small>"]
    sharedprefs[("SharedPreferences<br/><small>stats_collections · ajustes · tema</small>")]
    jsonIo("Exportar / Importar JSON<br/><small>file_picker · share_plus</small>")
  end
  usuario("Galería / Cámara<br/><small>captura de pantalla MLBB</small>")

  usuario -- "galería / cámara (image_picker)" --> uploadUi
  uploadUi -- "ProcessImageEvent ⇒ OcrResult" --> ocrBloc
  ocrBloc -- "OcrDataSource · texto (on-device)" --> mlkit
  uploadUi -- "parse + validate ⇒ ParseResult" --> parser
  uploadUi == "SaveStatsCollectionEvent (confirmación)" ==> uploadBloc
  uploadBloc -- "guarda StatsCollection" --> historyRepo
  historyRepo -- "'stats_collections' (JSON)" --> sharedprefs
  uploadBloc -. "dispara LoadAll (reload)" .-> historyBloc
  historyBloc -- "colecciones → charts" --> historyUi
  shellUi -- "SettingsBloc · ThemeBloc ⇒ datasources" --> sharedprefs
  historyRepo -. "exportar / importar" .-> jsonIo
```

> Versión interactiva: <https://rafael-vh.github.io/Insight/diagramas/insight-arquitectura/>

---

## Frontend · Flujo de interacción

Cómo viaja una interacción del gesto del usuario al redibujado del widget, por BLoCs y controllers.

```mermaid
flowchart LR
  classDef backend fill:#dcfce7,stroke:#059669,color:#052e16;
  classDef external fill:#e2e8f0,stroke:#64748b,color:#0f172a;
  classDef frontend fill:#dbeafe,stroke:#0891b2,color:#083344;
  classDef security fill:#ffe4e6,stroke:#e11d48,color:#4c0519;

  subgraph L0["Interfaz (gesto del usuario + widgets)"]
    tap("Gesto / tap<br/><small>acción del usuario</small>")
    screen(["Screen<br/><small>recibe el gesto</small>"])
    controller["StatsUploadController<br/><small>orquesta modos</small>"]
    widget(["BlocBuilder<br/><small>rebuild widget</small>"])
  end
  subgraph L1["Estado (BLoC / Controller / Parser)"]
    bloc["BLoC.add(event)<br/><small>despacha evento</small>"]
    parser["MlbbParser<br/><small>regex → stats</small>"]
    state[/"emit(state)<br/><small>nuevo estado</small>"/]
  end

  tap == "interacción" ==> screen
  screen -- "add(event)" --> bloc
  screen -- "invoca" --> controller
  controller -- "parse(texto)" --> parser
  parser -- "resultado" --> state
  bloc ==> state
  state == "rebuild" ==> widget
```

> Versión interactiva: <https://rafael-vh.github.io/Insight/diagramas/frontend-interaccion/>

---

## Insight · Datos extraídos de stats MLBB

Del png de la partida al JSON guardado: OCR on-device, parseo por regex, validación y consumo local.

```mermaid
flowchart LR
  classDef backend fill:#dcfce7,stroke:#059669,color:#052e16;
  classDef database fill:#ede9fe,stroke:#7c3aed,color:#2e1065;
  classDef external fill:#e2e8f0,stroke:#64748b,color:#0f172a;
  classDef frontend fill:#dbeafe,stroke:#0891b2,color:#083344;
  classDef messagebus fill:#ffedd5,stroke:#ea580c,color:#431407;

  subgraph E0["Captura"]
    imagen(["Imagen de stats<br/><small>cámara o galería</small>"])
  end
  subgraph E1["OCR"]
    mlkit("ML Kit OCR<br/><small>TextRecognizer · latin</small>")
  end
  subgraph E2["Parseo"]
    texto[["Texto plano<br/><small>recognizedText · \n</small>"]]
    parser["StatsParser<br/><small>22 regex sobre el string</small>"]
  end
  subgraph E3["Validación"]
    performance[("PlayerPerformance<br/><small>25 campos numéricos</small>")]
    validator["StatsValidator<br/><small>faltantes / advertencias</small>"]
  end
  subgraph E4["Almacén y consumo"]
    storage[("Colección local<br/><small>JSON · key stats_collections</small>")]
    consumers(["Consumo<br/><small>Historial · insights</small>"])
  end

  imagen == "archivo de imagen<br/>captura" ==> mlkit
  mlkit == "texto reconocido<br/>OCR" ==> texto
  texto == "fullText<br/>entrada del parser" ==> parser
  parser == "22 campos extraídos<br/>parseo" ==> performance
  performance -- "estado por campo<br/>validación" --> validator
  validator == "guardar sesión (válida)<br/>manual" ==> storage
  storage -- "lectura<br/>CRUD · export · gráficos" --> consumers
```

> Versión interactiva: <https://rafael-vh.github.io/Insight/diagramas/mlbb-extraccion/>
