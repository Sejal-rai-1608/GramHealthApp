from rag.config.sources import is_approved_medical_source_url


def test_approved_medical_source_requires_https_and_allowlisted_domain():
    assert is_approved_medical_source_url("https://www.who.int/news-room/fact-sheets")
    assert is_approved_medical_source_url("https://www.cdc.gov/health-topics")
    assert not is_approved_medical_source_url("http://www.who.int/news-room/fact-sheets")
    assert not is_approved_medical_source_url("https://example.com/medical-advice")
    assert not is_approved_medical_source_url("https://who.int.evil.example/medical")
