module SOLR

  class SolrSchemaGenerator

    attr_reader :schema

    def initialize
      @schema = {}
    end

    def add_field(name, type, indexed: true, stored: true, multi_valued: false)
      @schema['add-field'] ||= []
      @schema['add-field'] << { name: name.to_s, type: type, indexed: indexed, stored: stored, multiValued: multi_valued }
    end

    def add_dynamic_field(name, type, indexed: true, stored: true, multi_valued: false)
      @schema['add-dynamic-field'] ||= []
      @schema['add-dynamic-field'] << { name: name.to_s, type: type, indexed: indexed, stored: stored, multiValued: multi_valued }
    end

    def add_copy_field(source, dest)
      @schema['add-copy-field'] ||= []
      @schema['add-copy-field'] << { source: source, dest: dest }
    end

    def add_field_type(type_definition)
      @schema['add-field-type'] ||= []
      @schema['add-field-type'] << type_definition
    end

    def fields_to_add
      custom_fields = @schema['add-field'] || []
      custom_fields + init_fields
    end

    def dynamic_fields_to_add
      custom_fields = @schema['add-dynamic-field'] || []
      custom_fields + init_dynamic_fields
    end

    def copy_fields_to_add
      custom_fields = @schema['add-copy-field'] || []
      custom_fields + init_copy_fields
    end

    def field_types_to_add
      custom_fields = @schema['add-field-type'] || []
      custom_fields + init_fields_types
    end

    def init_fields_types
      [
        {
          "name": "string_ci",
          "class": "solr.TextField",
          "sortMissingLast": true,
          "omitNorms": true,
          "queryAnalyzer":
            {
              "type": "query",
              "tokenizer": {
                "class": "solr.KeywordTokenizerFactory"
              },
              "filter": [
                {
                  "class": "solr.LowerCaseFilterFactory"
                }
              ]
            }
        },
        {
          "name": "text_suggest_ngram",
          "class": "solr.TextField",
          indexAnalyzer: {
            "charFilter": [
              {
                "class": "solr.MappingCharFilterFactory",
                "mapping": "mapping-ISOLatin1Accent.txt"
              }
            ],
            "tokenizer": {
              "class": "solr.StandardTokenizerFactory"
            },
            "filter": [
              {
                "class": "solr.WordDelimiterGraphFilterFactory",
                "generateWordParts": true,
                "generateNumberParts": true,
                "catenateWords": false,
                "catenateNumbers": false,
                "catenateAll": false,
                "splitOnCaseChange": true
              },
              {
                "class": "solr.LowerCaseFilterFactory"
              },
              {
                "class": "solr.EdgeNGramFilterFactory",
                "maxGramSize": 20,
                "minGramSize": 1
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "([^\w\d*æøåÆØÅ ])",
                "replacement": "",
                "replace": "all"
              }
            ]
          },
          queryAnalyzer: {

            "charFilter": [
              {
                "class": "solr.MappingCharFilterFactory",
                "mapping": "mapping-ISOLatin1Accent.txt"
              }
            ],
            "tokenizer": {
              "class": "solr.StandardTokenizerFactory"
            },
            "filter": [
              {
                "class": "solr.WordDelimiterGraphFilterFactory",
                "generateWordParts": false,
                "generateNumberParts": false,
                "catenateWords": false,
                "catenateNumbers": false,
                "catenateAll": false,
                "splitOnCaseChange": false
              },
              {
                "class": "solr.LowerCaseFilterFactory"
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "([^\w\d*æøåÆØÅ ])",
                "replacement": "",
                "replace": "all"
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "^(.{20})(.*)?",
                "replacement": "$1",
                "replace": "all"
              }
            ]
          }
        },
        { "name": "text_suggest_edge",
          "class": "solr.TextField",
          indexAnalyzer: {
            "charFilter": [
              {
                "class": "solr.MappingCharFilterFactory",
                "mapping": "mapping-ISOLatin1Accent.txt"
              }
            ],
            "tokenizer": {
              "class": "solr.KeywordTokenizerFactory"
            },
            "filter": [
              {
                "class": "solr.LowerCaseFilterFactory"
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "([\\.,;:-_])",
                "replacement": " ",
                "replace": "all"
              },
              {
                "class": "solr.EdgeNGramFilterFactory",
                "maxGramSize": 30,
                "minGramSize": 1
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "([^\w\d*æøåÆØÅ ])",
                "replacement": "",
                "replace": "all"
              }
            ]
          },
          queryAnalyzer: {
            "charFilter": [
              {
                "class": "solr.MappingCharFilterFactory",
                "mapping": "mapping-ISOLatin1Accent.txt"
              }
            ],
            "tokenizer": {
              "class": "solr.KeywordTokenizerFactory"
            },
            "filter": [
              {
                "class": "solr.LowerCaseFilterFactory"
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "([\\.,;:-_])",
                "replacement": " ",
                "replace": "all"
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "([^\w\d*æøåÆØÅ ])",
                "replacement": "",
                "replace": "all"
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "^(.{30})(.*)?",
                "replacement": "$1",
                "replace": "all"
              }
            ]
          }
        },
        {
          "name": "text_suggest",
          "class": "solr.TextField",
          "positionIncrementGap": 100,
          indexAnalyzer: {
            "charFilter": [
              {
                "class": "solr.MappingCharFilterFactory",
                "mapping": "mapping-ISOLatin1Accent.txt"
              }
            ],
            "tokenizer": {
              "class": "solr.StandardTokenizerFactory"
            },
            "filter": [
              {
                "class": "solr.WordDelimiterGraphFilterFactory",
                "generateWordParts": true,
                "generateNumberParts": true,
                "catenateWords": true,
                "catenateNumbers": true,
                "catenateAll": true,
                "splitOnCaseChange": true,
                "splitOnNumerics": true,
                "preserveOriginal": true
              },
              {
                "class": "solr.LowerCaseFilterFactory"
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "([^\w\d*æøåÆØÅ ])",
                "replacement": " ",
                "replace": "all"
              }
            ]
          },
          queryAnalyzer: {
            "charFilter": [
              {
                "class": "solr.MappingCharFilterFactory",
                "mapping": "mapping-ISOLatin1Accent.txt"
              }
            ],
            "tokenizer": {
              "class": "solr.StandardTokenizerFactory"
            },
            "filter": [
              {
                "class": "solr.WordDelimiterGraphFilterFactory",
                "generateWordParts": false,
                "generateNumberParts": false,
                "catenateWords": false,
                "catenateNumbers": false,
                "catenateAll": false,
                "splitOnCaseChange": false,
                "splitOnNumerics": false
              },
              {
                "class": "solr.LowerCaseFilterFactory"
              },
              {
                "class": "solr.PatternReplaceFilterFactory",
                "pattern": "([^\w\d*æøåÆØÅ ])",
                "replacement": " ",
                "replace": "all"
              }
            ]
          }
        }
      ]
    end

    def init_fields
      [
        #{ name: "_version_", type: "plong", indexed: true, stored: true, multiValued: false },
        { name: "resource_id", type: "string", indexed: true, multiValued: false, required: true, stored: true },
        { name: "resource_model", type: "string", indexed: true, multiValued: false, required: true, stored: false },
        { name: "_text_", type: "text_general", indexed: true, multiValued: true, stored: false },
      ]
    end

    def init_dynamic_fields
      [
        { "name": "*_Exact", "type": "string_ci", "multiValued": true, stored: false },
        { "name": "*_Suggest", "type": "text_suggest", "omitNorms": true, stored: false, "multiValued": true },
        { "name": "*_SuggestEdge", "type": "text_suggest_edge", stored: false, "multiValued": true },
        { "name": "*_SuggestNgram", "type": "text_suggest_ngram", stored: false, "omitNorms": true, "multiValued": true },
        { "name": "*_text", "type": "text_general", stored: true, "multiValued": false },
        { "name": "*_texts", "type": "text_general", stored: true, "multiValued": true }
      ]
    end

    def init_copy_fields
      [
        { source: "*_text", dest: %w[_text_ *_Exact *_Suggest *_SuggestEdge *_SuggestNgram] },
        { source: "*_texts", dest: %w[_text_ *_Exact *_Suggest *_SuggestEdge *_SuggestNgram] }
      ]
    end
  end
end
