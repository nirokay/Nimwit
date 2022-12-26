import typedefs, tables

const config* = Config(
    prefix: ".",
    rollCommandLimit: 500,

    # Locations of all data files:
    fileLocations: {
        fileHelloList: "public/hello_list.json"
    }.toTable
)

export config
