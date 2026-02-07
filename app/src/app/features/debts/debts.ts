import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-debts',
  imports: [],
  templateUrl: './debts.html',
  styleUrl: './debts.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Debts {}
