require "rails_helper"

describe Legislation::DraftVersion do
  let(:legislation_draft_version) { build(:legislation_draft_version) }

  it_behaves_like "acts as paranoid", :legislation_draft_version
  it_behaves_like "globalizable", :legislation_draft_version

  it "is valid" do
    expect(legislation_draft_version).to be_valid
  end

  it "dynamically validates the valid statuses" do
    stub_const("#{Legislation::DraftVersion}::VALID_STATUSES", %w[custom])

    legislation_draft_version.status = "custom"
    expect(legislation_draft_version).to be_valid

    legislation_draft_version.status = "published"
    expect(legislation_draft_version).not_to be_valid
  end

  it "renders the html from the markdown body field" do
    legislation_draft_version.body = body_markdown

    legislation_draft_version.save!

    expect(legislation_draft_version.body_html).to eq(body_html)
    expect(legislation_draft_version.toc_html).to eq(toc_html)
  end

  it "renders the tables from the markdown body field" do
    legislation_draft_version.body = body_with_table_markdown

    legislation_draft_version.save!

    expect(legislation_draft_version.body_html).to eq(body_with_table_html)
    expect(legislation_draft_version.toc_html).to eq(toc_html)
  end

  it "does not add a target attribute to links" do
    legislation_draft_version.body = "A [link](/url)"

    expect(legislation_draft_version.body_html).to eq("<p>A <a href=\"/url\">link</a></p>\n")
  end

  def body_markdown
    <<~BODY_MARKDOWN
      # Title 1

      Some paragraph.

      A list:

      - item 1
      - item 2

      ## Subtitle

      Another paragraph.

      # Title 2

      Something about this.
    BODY_MARKDOWN
  end

  def body_with_table_markdown
    <<~BODY_MARKDOWN
      # Title 1

      Some paragraph.

      A list:

      - item 1
      - item 2

      ## Subtitle

      Another paragraph.

      # Title 2

      Something about this.

      | id | name    | age | gender |
      |----|---------|-----|--------|
      | 1  | Roberta | 39  | M      |
      | 2  | Oliver  | 25  | F      |
    BODY_MARKDOWN
  end

  def body_html
    <<~BODY_HTML
      <h1 id="title-1">Title 1</h1>

      <p>Some paragraph.</p>

      <p>A list:</p>

      <ul>
      <li>item 1</li>
      <li>item 2</li>
      </ul>

      <h2 id="subtitle">Subtitle</h2>

      <p>Another paragraph.</p>

      <h1 id="title-2">Title 2</h1>

      <p>Something about this.</p>
    BODY_HTML
  end

  def body_with_table_html
    <<~BODY_HTML
      <h1 id="title-1">Title 1</h1>

      <p>Some paragraph.</p>

      <p>A list:</p>

      <ul>
      <li>item 1</li>
      <li>item 2</li>
      </ul>

      <h2 id="subtitle">Subtitle</h2>

      <p>Another paragraph.</p>

      <h1 id="title-2">Title 2</h1>

      <p>Something about this.</p>

      <table><thead>
      <tr>
      <th>id</th>
      <th>name</th>
      <th>age</th>
      <th>gender</th>
      </tr>
      </thead><tbody>
      <tr>
      <td>1</td>
      <td>Roberta</td>
      <td>39</td>
      <td>M</td>
      </tr>
      <tr>
      <td>2</td>
      <td>Oliver</td>
      <td>25</td>
      <td>F</td>
      </tr>
      </tbody></table>
    BODY_HTML
  end

  def toc_html
    <<~TOC_HTML
      <ul>
      <li>
      <a href="#title-1">Title 1</a>
      <ul>
      <li>
      <a href="#subtitle">Subtitle</a>
      </li>
      </ul>
      </li>
      <li>
      <a href="#title-2">Title 2</a>
      </li>
      </ul>
    TOC_HTML
  end
end
