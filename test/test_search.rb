require_relative 'test_case'

module TestSearch

  class TermSearch < Goo::Base::Resource
    model :term_search, name_with: :id
    attribute :prefLabel, enforce: [:existence]
    attribute :synonym, enforce: [:list] # array of strings
    attribute :definition  # array of strings
    attribute :submissionAcronym, enforce: [:existence]
    attribute :submissionId, enforce: [:existence, :integer]

    # Dummy attributes to validate non-searchable files
    attribute :semanticType
    attribute :cui

    enable_indexing(:term_search) do
      schema_generator.add_field(:prefLabel, 'text_general', indexed: true, stored: true, multi_valued: false)
      schema_generator.add_field(:synonym, 'text_general', indexed: true, stored: true, multi_valued: true)
      schema_generator.add_field(:notation, 'text_general', indexed: true, stored: true, multi_valued: false)

      schema_generator.add_field(:definition, 'string', indexed: true, stored: true, multi_valued: true)
      schema_generator.add_field(:submissionAcronym, 'string', indexed: true, stored: true, multi_valued: false)
      schema_generator.add_field(:parents, 'string', indexed: true, stored: true, multi_valued: true)
      #schema_generator.add_field(:ontologyType, 'ontologyType', indexed: true, stored: true, multi_valued: false)
      schema_generator.add_field(:ontologyId, 'string', indexed: true, stored: true, multi_valued: false)
      schema_generator.add_field(:submissionId, 'pint', indexed: true, stored: true, multi_valued: false)
      schema_generator.add_field(:childCount, 'pint', indexed: true, stored: true, multi_valued: false)

      schema_generator.add_field(:cui, 'text_general', indexed: true, stored: true, multi_valued: true)
      schema_generator.add_field(:semanticType, 'text_general', indexed: true, stored: true, multi_valued: true)

      schema_generator.add_field(:property, 'text_general', indexed: true, stored: true, multi_valued: true)
      schema_generator.add_field(:propertyRaw, 'text_general', indexed: false, stored: true, multi_valued: false)

      schema_generator.add_field(:obsolete, 'boolean', indexed: true, stored: true, multi_valued: false)
      schema_generator.add_field(:provisional, 'boolean', indexed: true, stored: true, multi_valued: false)

      # Copy fields for term search
      schema_generator.add_copy_field('prefLabel', '_text_')
      schema_generator.add_copy_field('prefLabel', 'prefLabel_Exact')
      schema_generator.add_copy_field('prefLabel', 'prefLabel_Suggest')
      schema_generator.add_copy_field('prefLabel', 'prefLabel_SuggestEdge')
      schema_generator.add_copy_field('prefLabel', 'prefLabel_SuggestNgram')

      schema_generator.add_copy_field('synonym', '_text_')
      schema_generator.add_copy_field('synonym', 'synonym_Exact')
      schema_generator.add_copy_field('synonym', 'synonym_Suggest')
      schema_generator.add_copy_field('synonym', 'synonym_SuggestEdge')
      schema_generator.add_copy_field('synonym', 'synonym_SuggestNgram')

      schema_generator.add_copy_field('notation', '_text_')

      schema_generator.add_copy_field('prefLabel_*', 'prefLabel')
      schema_generator.add_copy_field('synonym_*', 'synonym')
    end

    def index_id()
      "#{self.id.to_s}_#{self.submissionAcronym}_#{self.submissionId}"
    end

    def index_doc(to_set = nil)
      self.to_hash
    end
  end

  class TermSearch2 < Goo::Base::Resource
    model :term_search2, name_with: :prefLabel
    attribute :prefLabel, enforce: [:existence], fuzzy_search: true
    attribute :synonym, enforce: [:list]
    attribute :definition
    attribute :submissionAcronym, enforce: [:existence]
    attribute :submissionId, enforce: [:existence, :integer]
    attribute :private, enforce: [:boolean], default: false, index: false
    # Dummy attributes to validate non-searchable files
    attribute :semanticType
    attribute :cui

    enable_indexing(:test_solr)
  end

  class TermSearch3 < Goo::Base::Resource
    model :term_search3, name_with: :prefLabel
    attribute :prefLabel, enforce: [:existence]
    attribute :synonym, enforce: [:list]
    attribute :definition
    attribute :submissionAcronym, enforce: [:existence]
    attribute :submissionId, enforce: [:existence, :integer]
    attribute :private, enforce: [:boolean], default: false, index: false
    # Dummy attributes to validate non-searchable files
    attribute :semanticType
    attribute :cui

    enable_indexing(:test_solr)
  end

  class TestModelSearch < MiniTest::Unit::TestCase

    def setup
      @terms = [
        TermSearch.new(
          id: RDF::URI.new("http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#Melanoma"),
          prefLabel: "Melanoma",
          synonym: [
            "Cutaneous Melanoma",
            "Skin Cancer",
            "Malignant Melanoma"
          ],
          definition: "Melanoma refers to a malignant skin cancer",
          submissionAcronym: "NCIT",
          submissionId: 2,
          semanticType: "Neoplastic Process",
          cui: "C0025202"
        ),
        TermSearch.new(
          id: RDF::URI.new("http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#Neoplasm"),
          prefLabel: "Neoplasm",
          synonym: [
            "tumor",
            "Neoplasms",
            "NEOPLASMS BENIGN",
            "MALIGNANT AND UNSPECIFIED (INCL CYSTS AND POLYPS)",
            "Neoplasia",
            "Neoplastic Growth"
          ],
          definition: "A benign or malignant tissue growth resulting from uncontrolled cell proliferation. "\
            "Benign neoplastic cells resemble normal cells without exhibiting significant cytologic atypia, while "\
            "malignant cells exhibit overt signs such as dysplastic features, atypical mitotic figures, necrosis, "\
            "nuclear pleomorphism, and anaplasia. Representative examples of benign neoplasms include papillomas, "\
            "cystadenomas, and lipomas; malignant neoplasms include carcinomas, sarcomas, lymphomas, and leukemias.",
          submissionAcronym: "NCIT",
          submissionId: 2,
          semanticType: "Neoplastic Process",
          cui: "C0375111"
        )
      ]
    end

    def initialize(*args)
      super(*args)
    end

    def test_search
      TermSearch.indexClear()
      @terms[1].index()
      TermSearch.indexCommit()
      resp = TermSearch.search(@terms[1].prefLabel)
      assert_equal(1, resp["response"]["docs"].length)
      assert_equal @terms[1].prefLabel, resp["response"]["docs"][0]["prefLabel"]
    end

    def test_unindex
      TermSearch.indexClear()
      @terms[1].index()
      TermSearch.indexCommit()
      resp = TermSearch.search(@terms[1].prefLabel)
      assert_equal(1, resp["response"]["docs"].length)

      @terms[1].unindex()
      TermSearch.indexCommit()
      resp = TermSearch.search(@terms[1].prefLabel)
      assert_equal(0, resp["response"]["docs"].length)
    end

    def test_unindexByQuery
      TermSearch.indexClear()
      @terms[1].index()
      TermSearch.indexCommit()
      resp = TermSearch.search(@terms[1].prefLabel)
      assert_equal 1, resp["response"]["docs"].length

      query = "submissionAcronym:" + @terms[1].submissionAcronym
      TermSearch.unindexByQuery(query)
      TermSearch.indexCommit()

      resp = TermSearch.search(@terms[1].prefLabel)
      assert_equal 0, resp["response"]["docs"].length
    end

    def test_index
      TermSearch.indexClear()
      @terms[0].index()
      TermSearch.indexCommit()
      resp = TermSearch.search(@terms[0].prefLabel)
      assert_equal 1, resp["response"]["docs"].length
      assert_equal @terms[0].prefLabel, resp["response"]["docs"][0]["prefLabel"]
    end

    def test_indexBatch
      TermSearch.indexClear()
      TermSearch.indexBatch(@terms)
      TermSearch.indexCommit()
      resp = TermSearch.search("*:*")
      assert_equal 2, resp["response"]["docs"].length
    end

    def test_unindexBatch
      TermSearch.indexClear()
      TermSearch.indexBatch(@terms)
      TermSearch.indexCommit()
      resp = TermSearch.search("*:*")
      assert_equal 2, resp["response"]["docs"].length

      TermSearch.unindexBatch(@terms)
      TermSearch.indexCommit()
      resp = TermSearch.search("*:*")
      assert_equal 0, resp["response"]["docs"].length
    end

    def test_indexClear
      TermSearch.indexClear()
      TermSearch.indexCommit()
      resp = TermSearch.search("*:*")
      assert_equal 0, resp["response"]["docs"].length
    end

    def test_index_on_save_delete
      TermSearch2.find("test").first&.delete
      TermSearch3.find("test2").first&.delete

      term = TermSearch2.new(prefLabel: "test",
                            submissionId: 1,
                            definition: "definition of test",
                            synonym: ["synonym1", "synonym2"],
                            submissionAcronym: "test",
                            private: true
      )

      term2 = TermSearch3.new(prefLabel: "test2",
                              submissionId: 1,
                              definition: "definition of test2",
                              synonym: ["synonym1", "synonym2"],
                              submissionAcronym: "test",
                              private: true
      )

      term.save
      term2.save

      # set as not indexed in model definition
      refute_includes TermSearch2.search_client.fetch_all_fields.map{|f| f["name"]}, "private_b"
      refute_includes TermSearch2.search_client.fetch_all_fields.map{|f| f["name"]}, "private_b"


      indexed_term = TermSearch2.search("id:#{term.id.to_s.gsub(":", "\\:")}")["response"]["docs"].first
      indexed_term2 = TermSearch3.search("id:#{term2.id.to_s.gsub(":", "\\:")}")["response"]["docs"].first

      term.indexable_object.each do |k, v|
        assert_equal v, indexed_term[k.to_s]
      end

      term2.indexable_object.each do |k, v|
        assert_equal v, indexed_term2[k.to_s]
      end

      term2.definition = "new definition of test2"
      term2.synonym = ["new synonym1", "new synonym2"]
      term2.save

      indexed_term2 = TermSearch3.search("id:#{term2.id.to_s.gsub(":", "\\:")}")["response"]["docs"].first

      term2.indexable_object.each do |k, v|
        assert_equal v, indexed_term2[k.to_s]
      end

      term2.delete
      term.delete

      indexed_term = TermSearch2.search("id:#{term.id.to_s.gsub(":", "\\:")}")["response"]["docs"].first
      indexed_term2 = TermSearch3.search("id:#{term2.id.to_s.gsub(":", "\\:")}")["response"]["docs"].first

      assert_nil indexed_term
      assert_nil indexed_term2

    end
  end

end
