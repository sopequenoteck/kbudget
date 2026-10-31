import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { ListSkeleton } from './list-skeleton';

@Component({
  standalone: true,
  template: `<app-list-skeleton [count]="count()" [hero]="hero()" [small]="small()" />`,
  imports: [ListSkeleton],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestHost {
  readonly count = signal(3);
  readonly hero = signal(false);
  readonly small = signal(false);
}

describe('ListSkeleton', () => {
  let fixture: ComponentFixture<TestHost>;
  let host: TestHost;
  let element: HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [TestHost] }).compileComponents();
    fixture = TestBed.createComponent(TestHost);
    host = fixture.componentInstance;
    fixture.detectChanges();
    element = fixture.nativeElement.querySelector('app-list-skeleton');
  });

  it('should_render_count_items_in_a_list_group', () => {
    const group = element.querySelector('.k-list-group');
    expect(group).not.toBeNull();
    expect(element.querySelectorAll('.k-list-group > .k-skeleton-item').length).toBe(3);
  });

  it('should_render_each_item_with_a_circle_a_title_a_subtitle_and_a_value', () => {
    const item = element.querySelector('.k-skeleton-item')!;
    expect(item.children.length).toBe(3);
    expect(item.children[0].className).toBe('k-skeleton-circle');
    expect(item.children[1].className).toBe('k-skeleton-lines');
    expect(item.children[2].className).toBe('k-skeleton-lines k-skeleton-lines--right');
    expect(item.querySelector('.k-skeleton-lines:not(.k-skeleton-lines--right) > .k-skeleton-line--title')).not.toBeNull();
    expect(item.querySelector('.k-skeleton-lines:not(.k-skeleton-lines--right) > .k-skeleton-line--subtitle')).not.toBeNull();
    expect(item.querySelector('.k-skeleton-lines--right > .k-skeleton-line--value')).not.toBeNull();
  });

  it('should_render_no_small_line_no_hero_and_no_margin_by_default', () => {
    expect(element.querySelector('.k-skeleton-line--small')).toBeNull();
    expect(element.querySelector('.k-skeleton-hero')).toBeNull();
    expect((element.querySelector('.k-list-group') as HTMLElement).style.marginTop).toBe('');
  });

  it('should_add_a_small_line_under_the_value_when_small_is_set', () => {
    host.small.set(true);
    fixture.detectChanges();

    const right = element.querySelectorAll('.k-skeleton-lines--right');
    expect(right.length).toBe(3);
    for (const lines of Array.from(right)) {
      expect(lines.children.length).toBe(2);
      expect(lines.children[1].className).toBe('k-skeleton-line k-skeleton-line--small');
    }
  });

  it('should_render_the_hero_skeleton_before_a_spaced_list_group_when_hero_is_set', () => {
    host.hero.set(true);
    fixture.detectChanges();

    const [hero, group] = Array.from(element.children);
    expect(hero.className).toBe('k-skeleton-hero');
    expect(Array.from(hero.children).map((bar) => bar.className)).toEqual([
      'k-skeleton-bar k-skeleton-bar--xs',
      'k-skeleton-bar k-skeleton-bar--lg',
      'k-skeleton-bar k-skeleton-bar--md',
      'k-skeleton-bar k-skeleton-bar--sm',
    ]);
    expect(group.className).toBe('k-list-group');
    expect((group as HTMLElement).style.marginTop).toBe('var(--k-space-4)');
  });

  it('should_render_an_empty_list_group_when_count_is_zero', () => {
    host.count.set(0);
    fixture.detectChanges();

    expect(element.querySelector('.k-list-group')).not.toBeNull();
    expect(element.querySelectorAll('.k-skeleton-item').length).toBe(0);
  });

  it('should_follow_count_changes', () => {
    host.count.set(1);
    fixture.detectChanges();
    expect(element.querySelectorAll('.k-skeleton-item').length).toBe(1);

    host.count.set(5);
    fixture.detectChanges();
    expect(element.querySelectorAll('.k-skeleton-item').length).toBe(5);
  });

  it('should_accept_hero_and_small_as_bare_attributes', async () => {
    @Component({
      standalone: true,
      template: `<app-list-skeleton hero small [count]="2" />`,
      imports: [ListSkeleton],
    })
    class BareHost {}
    const bare = TestBed.createComponent(BareHost);
    bare.detectChanges();

    const el: HTMLElement = bare.nativeElement;
    expect(el.querySelector('.k-skeleton-hero')).not.toBeNull();
    expect(el.querySelectorAll('.k-skeleton-line--small').length).toBe(2);
  });
});
