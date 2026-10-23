import {Injectable} from '@angular/core';
import {LoginCredential} from '../../../../common/entities/LoginCredential';
import {NetworkService} from './network.service';
import {UserDTO} from '../../../../common/entities/UserDTO';

@Injectable()
export class UserService {
  constructor(private networkService: NetworkService) {
  }

  public async logout(): Promise<string> {
    return this.networkService.postJson('/user/logout');
  }

  public async login(credential: LoginCredential): Promise<UserDTO> {
    return this.networkService.postJson<UserDTO>('/user/login', {
      loginCredential: credential,
    });
  }

  public async getSessionUser(): Promise<UserDTO> {
    return this.networkService.getJson<UserDTO>('/user/me');
  }
}
