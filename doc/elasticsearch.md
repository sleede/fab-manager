# ELASTICSEARCH

## Statistics

http://localhost:9200/stats/_mapping?pretty

    {
      "stats" : {
        "mappings" : {
          "machine" : {
            "properties" : {
              "age" : {
                "type" : "long"
              },
              "ca" : {
                "type" : "double"
              },
              "date" : {
                "type" : "date",
                "format" : "dateOptionalTime"
              },
              "gender" : {
                "type" : "string"
              },
              "group" : {
                "type" : "string"
              },
              "machineId" : {
                "type" : "long"
              },
              "name" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "reservationId" : {
                "type" : "long"
              },
              "stat" : {
                "type" : "long"
              },
              "subType" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "type" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "userId" : {
                "type" : "long"
              }
            }
          },
          "project" : {
            "properties" : {
              "age" : {
                "type" : "long"
              },
              "components" : {
                "properties" : {
                  "id" : {
                    "type" : "long"
                  },
                  "name" : {
                    "type" : "string"
                  }
                }
              },
              "date" : {
                "type" : "date",
                "format" : "dateOptionalTime"
              },
              "gender" : {
                "type" : "string"
              },
              "group" : {
                "type" : "string"
              },
              "licence" : {
                "type" : "object"
              },
              "machines" : {
                "properties" : {
                  "id" : {
                    "type" : "long"
                  },
                  "name" : {
                    "type" : "string"
                  }
                }
              },
              "name" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "projectId" : {
                "type" : "long"
              },
              "stat" : {
                "type" : "long"
              },
              "subType" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "themes" : {
                "properties" : {
                  "id" : {
                    "type" : "long"
                  },
                  "name" : {
                    "type" : "string"
                  }
                }
              },
              "type" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "userId" : {
                "type" : "long"
              },
              "users" : {
                "type" : "long"
              }
            }
          },
          "training" : {
            "properties" : {
              "age" : {
                "type" : "long"
              },
              "ca" : {
                "type" : "double"
              },
              "date" : {
                "type" : "date",
                "format" : "dateOptionalTime"
              },
              "gender" : {
                "type" : "string"
              },
              "group" : {
                "type" : "string"
              },
              "name" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "reservationId" : {
                "type" : "long"
              },
              "stat" : {
                "type" : "long"
              },
              "subType" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "trainingDate" : {
                "type" : "date",
                "format" : "dateOptionalTime"
              },
              "trainingId" : {
                "type" : "long"
              },
              "type" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "userId" : {
                "type" : "long"
              }
            }
          },
          "subscription" : {
            "properties" : {
              "age" : {
                "type" : "long"
              },
              "ca" : {
                "type" : "double"
              },
              "date" : {
                "type" : "date",
                "format" : "dateOptionalTime"
              },
              "gender" : {
                "type" : "string"
              },
              "group" : {
                "type" : "string"
              },
              "groupName" : {
                "type" : "string"
              },
              "invoiceItemId" : {
                "type" : "long"
              },
              "name" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "planId" : {
                "type" : "long"
              },
              "stat" : {
                "type" : "long"
              },
              "subType" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "subscriptionId" : {
                "type" : "long"
              },
              "type" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "userId" : {
                "type" : "long"
              }
            }
          },
          "user" : {
            "properties" : {
              "age" : {
                "type" : "long"
              },
              "date" : {
                "type" : "date",
                "format" : "dateOptionalTime"
              },
              "gender" : {
                "type" : "string"
              },
              "group" : {
                "type" : "string"
              },
              "name" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "stat" : {
                "type" : "long"
              },
              "subType" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "type" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "userId" : {
                "type" : "long"
              }
            }
          },
          "account" : {
            "properties" : {
              "age" : {
                "type" : "long"
              },
              "date" : {
                "type" : "date",
                "format" : "dateOptionalTime"
              },
              "gender" : {
                "type" : "string"
              },
              "group" : {
                "type" : "string"
              },
              "name" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "stat" : {
                "type" : "long"
              },
              "subType" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "type" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "userId" : {
                "type" : "long"
              }
            }
          },
          "event" : {
            "properties" : {
              "age" : {
                "type" : "long"
              },
              "ca" : {
                "type" : "double"
              },
              "date" : {
                "type" : "date",
                "format" : "dateOptionalTime"
              },
              "eventDate" : {
                "type" : "date",
                "format" : "dateOptionalTime"
              },
              "eventId" : {
                "type" : "long"
              },
              "gender" : {
                "type" : "string"
              },
              "group" : {
                "type" : "string"
              },
              "name" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "reservationId" : {
                "type" : "long"
              },
              "stat" : {
                "type" : "long"
              },
              "subType" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "type" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "userId" : {
                "type" : "long"
              },
              "ageRange" : {
                "type" : "string",
                "index" : "not_analyzed"
              },
              "eventTheme" : {
                "type" : "string",
                "index" : "not_analyzed"
              }
            }
          }
        }
      }
    }
