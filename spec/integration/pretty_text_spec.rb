# frozen_string_literal: true

require 'rails_helper'

describe PrettyText do
  it 'works with default markup' do
    cooked = PrettyText.cook("[topics]\n[/topics]")
    expect(cooked).to include("class=\"discourse-topic-query\"")
  end

  it 'doesn’t process invalid attribute' do
    cooked = PrettyText.cook("[topics baz=foo]\n[/topics]")
    expect(cooked).to_not include("baz")
  end

  it 'processes tags attribute' do
    cooked = PrettyText.cook("[topics tags=foo,bar]\n[/topics]")
    expect(cooked).to include("data-tags=\"foo,bar\"")
  end

  it 'processes status attribute' do
    cooked = PrettyText.cook("[topics status=open]\n[/topics]")
    expect(cooked).to include("data-status=\"open\"")
  end

  it 'processes order attribute' do
    cooked = PrettyText.cook("[topics order=created]\n[/topics]")
    expect(cooked).to include("data-order=\"created\"")
  end

  it 'processes topicIds attribute' do
    cooked = PrettyText.cook("[topics topicIds=1,2]\n[/topics]")
    expect(cooked).to include("data-topicids=\"1,2\"")
  end

  it 'processes exceptTopicIds attribute' do
    cooked = PrettyText.cook("[topics exceptTopicIds=1,2]\n[/topics]")
    expect(cooked).to include("data-excepttopicids=\"1,2\"")
  end

  it 'processes ascending attribute' do
    cooked = PrettyText.cook("[topics ascending=true]\n[/topics]")
    expect(cooked).to include("data-ascending=\"true\"")
  end

  it 'processes assigned attribute' do
    cooked = PrettyText.cook("[topics assigned=*]\n[/topics]")
    expect(cooked).to include("data-assigned=\"*\"")
  end

  it 'processes category attribute' do
    cooked = PrettyText.cook("[topics category=12]\n[/topics]")
    expect(cooked).to include("data-category=\"12\"")
  end
end
